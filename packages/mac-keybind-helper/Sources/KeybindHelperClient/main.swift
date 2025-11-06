import Foundation
import ArgumentParser
import KeybindHelperCore

extension String {
    var expandingTildeInPath: String {
        return NSString(string: self).expandingTildeInPath
    }
}

struct KeybindHelperClient: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Command line client for communicating with the keybind helper daemon",
        version: KeybindHelperVersion.current,
        subcommands: [Show.self, Hide.self, Quit.self]
    )
}

struct Show: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Show keymap overlay for the specified map"
    )
    
    @Argument(help: "Map ID to display")
    var mapId: String
    
    @Argument(help: "Path to configuration file")
    var configPath: String
    
    func validate() throws {
        let trimmedMapId = mapId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMapId.isEmpty else {
            throw ValidationError("Map ID cannot be empty")
        }
        
        let expandedPath = configPath.hasPrefix("~") ? configPath.expandingTildeInPath : configPath
        guard FileManager.default.fileExists(atPath: expandedPath) else {
            throw ValidationError("Configuration file does not exist at path: \(expandedPath)")
        }
    }
    
    func run() throws {
        let command = Command.show(
            mapId: mapId.trimmingCharacters(in: .whitespacesAndNewlines),
            configPath: configPath.hasPrefix("~") ? configPath.expandingTildeInPath : configPath
        )
        try executeCommand(command)
    }
}

struct Hide: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Hide the current overlay"
    )
    
    func run() throws {
        try executeCommand(.hide)
    }
}

struct Quit: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Quit the daemon"
    )
    
    func run() throws {
        try executeCommand(.quit)
    }
}

func executeCommand(_ command: Command) throws {
    let client = PipeClient()
    
    let response = try client.sendCommand(command)
    
    switch response {
    case .success:
        break
    case .error(let message):
        print("Daemon error: \(message)")
        throw ClientError.daemonError(message)
    }
}


enum ClientError: Error, LocalizedError {
    case daemonError(String)
    
    var errorDescription: String? {
        switch self {
        case .daemonError(let message):
            return message
        }
    }
}

KeybindHelperClient.main()