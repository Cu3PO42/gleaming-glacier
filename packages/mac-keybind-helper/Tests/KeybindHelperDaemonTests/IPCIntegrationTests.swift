import XCTest
@testable import KeybindHelperCore
@testable import KeybindHelperDaemon
@testable import KeybindHelperClient

final class IPCIntegrationTests: XCTestCase {
    
    func testIPCServerClientCommunication() throws {
        let testSocketPath = "/tmp/test-ipc-communication.sock"
        let server = IPCServer(socketPath: testSocketPath)
        let client = IPCClient(socketPath: testSocketPath, timeout: 2.0)
        
        // Clean up any existing socket
        try? FileManager.default.removeItem(atPath: testSocketPath)
        
        var receivedCommand: Command?
        let expectation = XCTestExpectation(description: "Command received")
        
        // Set up command handler
        server.commandHandler = { command, respond in
            receivedCommand = command
            respond(.success)
            expectation.fulfill()
        }
        
        // Start server
        try server.start()
        
        // Give server time to start
        Thread.sleep(forTimeInterval: 0.1)
        
        // Send command from client
        let testCommand = Command.show(mapId: "test", configPath: "/test/path")
        let response = try client.sendCommand(testCommand)
        
        // Wait for command to be received
        wait(for: [expectation], timeout: 3.0)
        
        // Verify command was received correctly
        XCTAssertEqual(receivedCommand, testCommand)
        XCTAssertEqual(response, .success)
        
        // Clean up
        server.stop()
    }
    
    override func tearDown() {
        super.tearDown()
        
        // Clean up any test socket files
        let testPaths = [
            "/tmp/test-ipc-communication.sock"
        ]
        
        for path in testPaths {
            try? FileManager.default.removeItem(atPath: path)
        }
    }
}