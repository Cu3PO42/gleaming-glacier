import Foundation
import KeybindHelperCore

/// Client for communicating with the daemon via named pipes
public class PipeClient {
    private let pipePath: String
    private let timeout: TimeInterval
    
    public init(pipePath: String = IPCConstants.defaultPipePath, timeout: TimeInterval = 5.0) {
        self.pipePath = pipePath
        self.timeout = timeout
    }
    
    /// Send a command to the daemon and wait for response
    public func sendCommand(_ command: Command) throws -> CommandResponse {
        // Check if pipe exists
        guard FileManager.default.fileExists(atPath: pipePath) else {
            throw IPCError.daemonNotRunning
        }
        
        do {
            // Encode command to JSON
            let commandData = try command.encoded()
            
            // Write command to pipe using file handle
            let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: pipePath))
            defer { fileHandle.closeFile() }
            fileHandle.write(commandData)
            
            // Wait for response from response pipe
            let responsePipePath = pipePath + ".response"
            
            // Wait for response with timeout
            let startTime = Date()
            while !FileManager.default.fileExists(atPath: responsePipePath) {
                if Date().timeIntervalSince(startTime) > timeout {
                    throw IPCError.connectionTimeout
                }
                Thread.sleep(forTimeInterval: 0.01) // 10ms polling
            }
            
            // Read response
            let responseData = try Data(contentsOf: URL(fileURLWithPath: responsePipePath))
            
            // Clean up response file
            try? FileManager.default.removeItem(atPath: responsePipePath)
            
            // Decode response
            return try CommandResponse.decoded(from: responseData)
            
        } catch let error as IPCError {
            throw error
        } catch {
            throw IPCError.connectionFailed(error)
        }
    }
}

