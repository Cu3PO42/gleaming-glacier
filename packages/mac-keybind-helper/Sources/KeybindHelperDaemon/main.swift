import Foundation
import Cocoa
import KeybindHelperCore

/// Background daemon that runs without GUI
class KeybindHelperDaemon {
    private var pipeServer: PipeServer?
    private var swiftUIWindowController: SwiftUIOverlayWindowController?
    private var currentKeymap: Keymap?
    private var isOverlayVisible: Bool = false
    private var currentConfiguration: KeymapConfiguration?
    private var configurationFilePath: String?
    private var shouldTerminate = false
    private let runLoop = RunLoop.current
    
    init() {
        setupSignalHandlers()
        setupComponents()
    }
    
    private func setupComponents() {
        // No components to initialize
    }
    
    private func setupSignalHandlers() {
        // Handle SIGTERM for graceful shutdown
        signal(SIGTERM) { _ in
            DispatchQueue.main.async {
                KeybindHelperDaemon.shared.gracefulShutdown()
            }
        }
        
        // Handle SIGINT (Ctrl+C) for graceful shutdown
        signal(SIGINT) { _ in
            DispatchQueue.main.async {
                KeybindHelperDaemon.shared.gracefulShutdown()
            }
        }
        
        // Handle SIGHUP for configuration reload
        signal(SIGHUP) { _ in
            DispatchQueue.main.async {
                AppLogger.daemon.info("Configuration reload requested via signal")
            }
        }
    }
    
    /// Start the daemon with pipe server
    func startDaemon() {
        AppLogger.daemon.info("KeybindHelper Daemon v\(KeybindHelperVersion.current) starting...")
        AppLogger.daemon.info("Starting pipe server...")
        
        // Start pipe server
        do {
            self.pipeServer = PipeServer()
            
            // Set up command handler for pipe server
            self.pipeServer?.commandHandler = { [weak self] command, responseHandler in
                self?.handleCommand(command, responseHandler: responseHandler)
            }
            
            try self.pipeServer?.start()
            AppLogger.daemon.info("Daemon started successfully")
        } catch {
            AppLogger.daemon.critical("Failed to start pipe server: \(error.localizedDescription)")
            gracefulShutdown()
            return
        }
        
        
        // Keep the daemon running
        while !shouldTerminate {
            runLoop.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
        }
        
        AppLogger.daemon.info("Daemon shutdown complete")
    }
    
    /// Handle incoming IPC commands
    private func handleCommand(_ command: Command, responseHandler: @escaping (CommandResponse) -> Void) {
        AppLogger.daemon.info("Handling command: \(String(describing: command))")
        
            switch command {
            case .show(let mapId, let configPath):
                handleShowCommand(mapId: mapId, configPath: configPath, responseHandler: responseHandler)
                
            case .hide:
                handleHideCommand(responseHandler: responseHandler)
                

                
            case .quit:
                AppLogger.daemon.info("Quit command received")
                responseHandler(.success)
                gracefulShutdown()
            }
    }
    
    /// Handle show command - load configuration and display keymap
    private func handleShowCommand(mapId: String, configPath: String, responseHandler: @escaping (CommandResponse) -> Void) {
        AppLogger.daemon.info("Show command received - mapId: \(mapId), configPath: \(configPath)")
        
        // Load configuration if not already loaded or if path changed
        if configurationFilePath != configPath {
            AppLogger.config.info("Loading configuration from: \(configPath)")
            
            let result = loadConfiguration(from: configPath)
            switch result {
            case .failure(let error):
                let errorMsg = "Failed to load configuration: \(error.localizedDescription)"
                AppLogger.config.error("\(errorMsg)")
                responseHandler(.error(message: errorMsg))
                return
            case .success:
                AppLogger.config.info("Configuration loaded successfully")
            }
        }
        
        // Get the requested keymap
        guard let keymap = keymap(withId: mapId) else {
            let errorMsg = "Keymap '\(mapId)' not found in configuration"
            AppLogger.config.error("\(errorMsg)")
            responseHandler(.error(message: errorMsg))
            return
        }
        
        AppLogger.config.info("Found keymap '\(mapId)' with \(keymap.binds.count) bindings")
        
        // Show the overlay with the keymap
        DispatchQueue.main.async {
            self.showOverlay(with: keymap)
            AppLogger.window.info("Overlay shown successfully")
            responseHandler(.success)
        }
    }
    
    /// Handle hide command - hide the overlay
    private func handleHideCommand(responseHandler: @escaping (CommandResponse) -> Void) {
        AppLogger.daemon.info("Hide command received")
        
        DispatchQueue.main.async {
            self.hideOverlay()
            AppLogger.window.info("Overlay hidden successfully")
            responseHandler(.success)
        }
    }
    
    // MARK: - Configuration Management Methods
    
    /// Load configuration from file path
    /// - Parameter filePath: Path to the configuration file
    /// - Returns: Result containing the loaded configuration or error
    @discardableResult
    private func loadConfiguration(from filePath: String) -> Result<KeymapConfiguration, ConfigurationError> {
        do {
            let configuration = try ConfigurationParser.parseConfiguration(from: filePath)
            self.currentConfiguration = configuration
            self.configurationFilePath = filePath
            return .success(configuration)
        } catch let error as ConfigurationError {
            return .failure(error)
        } catch {
            return .failure(.decodingFailed(error))
        }
    }
    
    /// Get a keymap by ID from the current configuration
    /// - Parameter id: The keymap ID
    /// - Returns: The keymap if found, nil otherwise
    private func keymap(withId id: String) -> Keymap? {
        return currentConfiguration?.keymap(withId: id)
    }
    
    // MARK: - Overlay Management Methods
    
    /// Show the overlay with the specified keymap
    /// - Parameters:
    ///   - keymap: The keymap to display
    ///   - animated: Whether to animate the appearance (default: true)
    private func showOverlay(with keymap: Keymap, animated: Bool = true) {
        // Store the current keymap
        currentKeymap = keymap
        
        // Create window if it doesn't exist
        if swiftUIWindowController == nil {
            swiftUIWindowController = SwiftUIOverlayWindowController()
        }
        
        guard let windowController = swiftUIWindowController else {
            AppLogger.window.error("Failed to create overlay window")
            return
        }
        
        // Update content and show window
        windowController.updateKeymap(keymap)
        
        if animated {
            windowController.showWithAnimation()
        } else {
            windowController.window?.makeKeyAndOrderFront(nil)
        }
        
        isOverlayVisible = true
    }
    
    /// Hide the overlay window
    /// - Parameter animated: Whether to animate the disappearance (default: true)
    private func hideOverlay(animated: Bool = true) {
        guard let windowController = swiftUIWindowController, isOverlayVisible else { return }
        
        if animated {
            windowController.hideWithAnimation()
        } else {
            windowController.window?.orderOut(nil)
        }
        
        isOverlayVisible = false
    }
    
    /// Perform graceful shutdown
    func gracefulShutdown() {
        guard !shouldTerminate else { return }
        shouldTerminate = true
        
        AppLogger.daemon.info("Performing graceful shutdown...")
        
        // Hide overlay if visible
        if isOverlayVisible {
            AppLogger.daemon.info("Hiding overlay before shutdown")
            DispatchQueue.main.sync {
                self.hideOverlay(animated: false)
            }
        }
        
        // Stop pipe server
        AppLogger.daemon.info("Stopping pipe server")
        pipeServer?.stop()
        pipeServer = nil
        
        // Clean up components
        AppLogger.daemon.info("Cleaning up components")
        swiftUIWindowController = nil
        currentKeymap = nil
        currentConfiguration = nil
        configurationFilePath = nil
        
        AppLogger.daemon.info("Graceful shutdown complete")
    }
    
    static let shared = KeybindHelperDaemon()
}

// MARK: - Main Entry Point

// Initialize logging
AppLogger.setupLogging()

// Start the daemon
KeybindHelperDaemon.shared.startDaemon()