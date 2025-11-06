import XCTest
@testable import KeybindHelperCore

final class CommandsIPCTests: XCTestCase {
    
    func testCommandEncodingDecoding() throws {
        let commands: [Command] = [
            .show(mapId: "main", configPath: "/path/to/config.json"),
            .hide,
            .quit
        ]
        
        for command in commands {
            let encoded = try command.encoded()
            let decoded = try Command.decoded(from: encoded)
            XCTAssertEqual(command, decoded)
        }
    }
    
    func testCommandResponseEncodingDecoding() throws {
        let responses: [CommandResponse] = [
            .success,
            .error(message: "Test error message")
        ]
        
        for response in responses {
            let encoded = try response.encoded()
            let decoded = try CommandResponse.decoded(from: encoded)
            XCTAssertEqual(response, decoded)
        }
    }
}