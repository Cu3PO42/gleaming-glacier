import Foundation

/// Configuration for customizing key display strings
public struct KeyDisplayConfiguration: Codable {
    /// Mapping from key names to their display representations
    public let keyMappings: [String: String]
    
    public init(keyMappings: [String: String] = [:]) {
        self.keyMappings = keyMappings
    }
}

/// Manager for loading key display configuration
public class KeyDisplayConfigurationManager {
    private static var cachedConfig: KeyDisplayConfiguration?
    
    /// Get the XDG config directory path
    private static var xdgConfigPath: String {
        if let xdgConfigHome = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"],
           !xdgConfigHome.isEmpty {
            return xdgConfigHome
        }
        
        let homeDir = NSHomeDirectory()
        return "\(homeDir)/.config"
    }
    
    /// Get the full path to the maestro-display config directory
    private static var configDirectory: String {
        return "\(xdgConfigPath)/maestro-display"
    }
    
    /// Get the full path to the key display config file
    private static var configFilePath: String {
        return "\(configDirectory)/key-display.json"
    }
    
    /// Load the key display configuration from file or return empty config
    public static func loadConfiguration() -> KeyDisplayConfiguration {
        if let cached = cachedConfig {
            return cached
        }
        
        let config = loadFromFile() ?? KeyDisplayConfiguration()
        cachedConfig = config
        return config
    }
    
    /// Reload configuration from file, bypassing cache
    public static func reloadConfiguration() -> KeyDisplayConfiguration {
        cachedConfig = nil
        return loadConfiguration()
    }
    
    // MARK: - Private Methods
    
    private static func loadFromFile() -> KeyDisplayConfiguration? {
        guard FileManager.default.fileExists(atPath: configFilePath) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: configFilePath))
            let decoder = JSONDecoder()
            return try decoder.decode(KeyDisplayConfiguration.self, from: data)
        } catch {
            // If config file is corrupted, log error and return nil to use empty config
            print("Warning: Failed to load key display configuration from \(configFilePath): \(error)")
            return nil
        }
    }
}