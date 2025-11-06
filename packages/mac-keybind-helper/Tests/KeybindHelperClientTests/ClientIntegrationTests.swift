import XCTest
@testable import KeybindHelperCore
@testable import KeybindHelperClient

final class ClientIntegrationTests: XCTestCase {
    
    func testCommandArgumentParsing() {
        // Test valid show command encoding
        let showCommand = Command.show(mapId: "main", configPath: "config.json")
        XCTAssertNoThrow(try showCommand.encoded())
        
        // Test hide command
        let hideCommand = Command.hide
        XCTAssertNoThrow(try hideCommand.encoded())
        
        // Test show command with different parameters
        let showCommand2 = Command.show(mapId: "submenu", configPath: "other.json")
        XCTAssertNoThrow(try showCommand2.encoded())
        
        // Test quit command
        let quitCommand = Command.quit
        XCTAssertNoThrow(try quitCommand.encoded())
    }
    
    func testCommandResponseHandling() {
        // Test success response
        let successResponse = CommandResponse.success
        XCTAssertNoThrow(try successResponse.encoded())
        
        // Test error response
        let errorResponse = CommandResponse.error(message: "Test error")
        XCTAssertNoThrow(try errorResponse.encoded())
        
        // Test round-trip encoding/decoding
        do {
            let encoded = try errorResponse.encoded()
            let decoded = try CommandResponse.decoded(from: encoded)
            XCTAssertEqual(decoded, errorResponse)
        } catch {
            XCTFail("Failed to encode/decode error response: \(error)")
        }
    }
    
    func testIPCClientTimeout() {
        // Test that client respects timeout settings
        let client = IPCClient(socketPath: "/tmp/nonexistent-test-socket", timeout: 0.1)
        
        let startTime = Date()
        XCTAssertThrowsError(try client.sendCommand(.hide)) { error in
            let elapsed = Date().timeIntervalSince(startTime)
            // Should timeout quickly (within reasonable bounds)
            XCTAssertLessThan(elapsed, 1.0)
            XCTAssertTrue(error is IPCError)
        }
    }
    
    func testCommandEquality() {
        // Test command equality for proper comparison
        let command1 = Command.show(mapId: "main", configPath: "/path/to/config")
        let command2 = Command.show(mapId: "main", configPath: "/path/to/config")
        let command3 = Command.show(mapId: "other", configPath: "/path/to/config")
        
        XCTAssertEqual(command1, command2)
        XCTAssertNotEqual(command1, command3)
        
        XCTAssertEqual(Command.hide, Command.hide)
        XCTAssertEqual(Command.quit, Command.quit)
        XCTAssertNotEqual(Command.hide, Command.quit)
    }
}