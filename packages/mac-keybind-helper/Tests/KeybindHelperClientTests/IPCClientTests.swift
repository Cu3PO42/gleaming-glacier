import XCTest
@testable import KeybindHelperCore
@testable import KeybindHelperClient

final class IPCClientTests: XCTestCase {
    
    func testIPCClientConnectionFailure() {
        let testSocketPath = "/tmp/nonexistent-keybind-helper.sock"
        let client = IPCClient(socketPath: testSocketPath, timeout: 1.0)
        
        // Ensure socket doesn't exist
        try? FileManager.default.removeItem(atPath: testSocketPath)
        
        // Test connection failure
        XCTAssertThrowsError(try client.sendCommand(.hide)) { error in
            XCTAssertTrue(error is IPCError)
        }
    }
    
    override func tearDown() {
        super.tearDown()
        
        // Clean up any test socket files
        let testPaths = [
            "/tmp/nonexistent-keybind-helper.sock"
        ]
        
        for path in testPaths {
            try? FileManager.default.removeItem(atPath: path)
        }
    }
}