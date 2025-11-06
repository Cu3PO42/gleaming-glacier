import Foundation
import KeybindHelperCore

/// Named pipe server for handling IPC communication with clients
public class PipeServer {
    private let pipePath: String
    private var isRunning = false
    private let queue = DispatchQueue(label: "pipe-server", qos: .userInitiated)
    
    /// Callback for handling received commands
    public var commandHandler: ((Command, @escaping (CommandResponse) -> Void) -> Void)?
    
    public init(pipePath: String = IPCConstants.defaultPipePath) {
        self.pipePath = pipePath
    }
    
    /// Start the pipe server
    public func start() throws {
        // Remove existing pipe if it exists
        try? FileManager.default.removeItem(atPath: pipePath)
        
        // Create named pipe using Foundation - no unsafe code
        guard mkfifo(pipePath, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP) == 0 else {
            throw IPCError.connectionFailed(POSIXError(POSIXErrorCode(rawValue: errno) ?? .ENOENT))
        }
        
        isRunning = true
        
        // Start handling connections on background queue
        queue.async { [weak self] in
            self?.handleConnections()
        }
        
        AppLogger.ipc.info("Pipe Server started on: \(self.pipePath)")
    }
    
    /// Stop the pipe server
    public func stop() {
        isRunning = false
        
        // Clean up pipe file
        try? FileManager.default.removeItem(atPath: pipePath)
        
        AppLogger.ipc.info("Pipe Server stopped")
    }
    
    private func handleConnections() {
        while isRunning {
            do {
                // Open pipe for reading - this blocks until a client connects
                let fileHandle = try FileHandle(forReadingFrom: URL(fileURLWithPath: pipePath))
                
                AppLogger.ipc.debug("Client connected")
                
                // Handle the connection
                handleClient(fileHandle: fileHandle)
                
                fileHandle.closeFile()
                AppLogger.ipc.debug("Client disconnected")
                
            } catch {
                if isRunning {
                    AppLogger.ipc.error("Error accepting connection: \(error.localizedDescription)")
                    Thread.sleep(forTimeInterval: 0.1) // Brief pause before retrying
                }
            }
        }
    }
    
    private func handleClient(fileHandle: FileHandle) {
        do {
            // Read all data from the pipe
            let data = fileHandle.readDataToEndOfFile()
            
            guard !data.isEmpty else {
                AppLogger.ipc.debug("Received empty data from client")
                return
            }
            
            // Decode command using safe JSON decoding
            let command = try Command.decoded(from: data)
            AppLogger.ipc.debug("Received command: \(String(describing: command))")
            
            // Handle the command
            let semaphore = DispatchSemaphore(value: 0)
            var response: CommandResponse = .error(message: "No response")
            
            commandHandler?(command) { commandResponse in
                response = commandResponse
                semaphore.signal()
            }
            
            semaphore.wait()
            
            // Send response back via a response pipe
            sendResponse(response, for: command)
            
        } catch {
            AppLogger.ipc.error("Error processing command: \(error.localizedDescription)")
            let errorResponse = CommandResponse.error(message: "Invalid command format: \(error.localizedDescription)")
            sendResponse(errorResponse, for: nil)
        }
    }
    
    private func sendResponse(_ response: CommandResponse, for command: Command?) {
        do {
            let responseData = try response.encoded()
            let responsePipePath = pipePath + ".response"
            
            // Write response to a response pipe
            try responseData.write(to: URL(fileURLWithPath: responsePipePath))
            
            AppLogger.ipc.debug("Response sent successfully")
            
        } catch {
            AppLogger.ipc.error("Error sending response: \(error.localizedDescription)")
        }
    }
}