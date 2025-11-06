// KeybindHelperCore - Core functionality for the macOS keybinding helper

// Re-export all public types and functions
@_exported import Foundation

// MARK: - Public API

/// Version information
public struct KeybindHelperVersion {
    public static let current = "1.0.0"
    public static let buildDate = "2025-07-20"
}

/// Main entry point for core functionality
public enum KeybindHelperCore {
    
    /// Parse a configuration file and return the keymap configuration
    public static func loadConfiguration(from path: String) throws -> KeymapConfiguration {
        return try ConfigurationParser.parseConfiguration(from: path)
    }
    
    /// Validate a configuration without loading from file
    public static func validateConfiguration(data: Data) throws -> KeymapConfiguration {
        return try ConfigurationParser.parseConfiguration(from: data)
    }
    
    /// Create a command for IPC communication
    public static func createCommand(_ command: Command) -> Data? {
        return try? command.encoded()
    }
    
    /// Parse a command from IPC data
    public static func parseCommand(from data: Data) -> Command? {
        return try? Command.decoded(from: data)
    }
    
    /// Create a response for IPC communication
    public static func createResponse(_ response: CommandResponse) -> Data? {
        return try? response.encoded()
    }
    
    /// Parse a response from IPC data
    public static func parseResponse(from data: Data) -> CommandResponse? {
        return try? CommandResponse.decoded(from: data)
    }
    

}