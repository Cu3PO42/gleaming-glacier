import Foundation

// MARK: - Legacy Command Models (for reference/migration)

/// Commands that can be sent to the daemon
public enum Command: Codable, Equatable {
    case show(mapId: String, configPath: String)
    case hide
    case quit
    
    /// Encode command to JSON data for IPC transmission
    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(self)
    }
    
    /// Decode command from JSON data received via IPC
    public static func decoded(from data: Data) throws -> Command {
        let decoder = JSONDecoder()
        return try decoder.decode(Command.self, from: data)
    }
}

/// Response from daemon to client
public enum CommandResponse: Codable, Equatable {
    case success
    case error(message: String)
    
    /// Encode response to JSON data for IPC transmission
    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(self)
    }
    
    /// Decode response from JSON data received via IPC
    public static func decoded(from data: Data) throws -> CommandResponse {
        let decoder = JSONDecoder()
        return try decoder.decode(CommandResponse.self, from: data)
    }
}