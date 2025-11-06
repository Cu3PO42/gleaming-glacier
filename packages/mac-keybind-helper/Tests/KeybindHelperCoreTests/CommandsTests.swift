import XCTest
@testable import KeybindHelperCore

final class CommandsTests: XCTestCase {
    
    func testCommandShowEncoding() throws {
        let command = Command.show(mapId: "main", configPath: "/path/to/config.json")
        let data = try command.encoded()
        let decoded = try Command.decoded(from: data)
        
        XCTAssertEqual(command, decoded)
    }
    
    func testCommandHideEncoding() throws {
        let command = Command.hide
        let data = try command.encoded()
        let decoded = try Command.decoded(from: data)
        
        XCTAssertEqual(command, decoded)
    }
    
    func testCommandShowWithDifferentPath() throws {
        let command = Command.show(mapId: "submenu", configPath: "/different/path.json")
        let data = try command.encoded()
        let decoded = try Command.decoded(from: data)
        
        XCTAssertEqual(command, decoded)
    }
    
    func testCommandQuitEncoding() throws {
        let command = Command.quit
        let data = try command.encoded()
        let decoded = try Command.decoded(from: data)
        
        XCTAssertEqual(command, decoded)
    }
    
    func testCommandResponseSuccessEncoding() throws {
        let response = CommandResponse.success
        let data = try response.encoded()
        let decoded = try CommandResponse.decoded(from: data)
        
        XCTAssertEqual(response, decoded)
    }
    
    func testCommandResponseErrorEncoding() throws {
        let response = CommandResponse.error(message: "Test error message")
        let data = try response.encoded()
        let decoded = try CommandResponse.decoded(from: data)
        
        XCTAssertEqual(response, decoded)
    }
    
    func testInvalidCommandDecoding() {
        let invalidJSON = "invalid json".data(using: .utf8)!
        
        XCTAssertThrowsError(try Command.decoded(from: invalidJSON))
    }
}