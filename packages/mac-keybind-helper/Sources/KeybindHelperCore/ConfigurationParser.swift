import Foundation

// MARK: - Configuration Parsing

/// Errors that can occur during configuration parsing
public enum ConfigurationError: Error, LocalizedError {
    case fileNotFound(path: String)
    case decodingFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Configuration file not found: \(path)"
        case .decodingFailed(let error):
            return "Failed to parse configuration: \(error.localizedDescription)"
        }
    }
}

/// Simple parser for keybinding configuration files
public class ConfigurationParser {
    
    /// Parse configuration from file path
    public static func parseConfiguration(from filePath: String) throws -> KeymapConfiguration {
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw ConfigurationError.fileNotFound(path: filePath)
        }
        
        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        return try parseConfiguration(from: data)
    }
    
    /// Parse configuration from JSON data
    public static func parseConfiguration(from data: Data) throws -> KeymapConfiguration {
        do {
            let configuration = try JSONDecoder().decode(KeymapConfiguration.self, from: data)
            return configuration
        } catch let error as ConfigurationError {
            throw error
        } catch {
            throw ConfigurationError.decodingFailed(error)
        }
    }
}