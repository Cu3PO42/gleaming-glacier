import Foundation

/// Errors that can occur during IPC communication
public enum IPCError: Error, LocalizedError {
    case connectionTimeout
    case connectionFailed(Error)
    case daemonNotRunning
    
    public var errorDescription: String? {
        switch self {
        case .connectionTimeout:
            return "Connection to daemon timed out"
        case .connectionFailed(let error):
            return "Failed to connect to daemon: \(error.localizedDescription)"
        case .daemonNotRunning:
            return "Daemon is not running"
        }
    }
}

/// Constants for IPC communication
public struct IPCConstants {
    public static let defaultPipePath = "/tmp/keybind-helper.pipe"
}