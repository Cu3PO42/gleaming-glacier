import Foundation
import Logging

public struct AppLogger {
    public enum Category: String, CaseIterable {
        case daemon = "daemon"
        case ipc = "ipc"
        case window = "window"
        case config = "config"
        case client = "client"
        case general = "general"
        
        var logger: Logger {
            return Logger(label: "com.keybindhelper.\(self.rawValue)")
        }
    }
    
    public static let daemon = Category.daemon.logger
    public static let ipc = Category.ipc.logger
    public static let window = Category.window.logger
    public static let config = Category.config.logger
    public static let client = Category.client.logger
    public static let general = Category.general.logger
    
    public static func setupLogging() {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .info
            return handler
        }
    }
}