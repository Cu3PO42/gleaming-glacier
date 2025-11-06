import XCTest
@testable import KeybindHelperCore
@testable import KeybindHelperDaemon

final class IPCServerTests: XCTestCase {
    
    func testIPCServerStartStop() throws {
        let testSocketPath = "/tmp/test-keybind-helper.sock"
        let server = IPCServer(socketPath: testSocketPath)
        
        // Clean up any existing socket
        try? FileManager.default.removeItem(atPath: testSocketPath)
        
        // Test starting server
        try server.start()
        
        // Verify socket file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: testSocketPath))
        
        // Test stopping server
        server.stop()
        
        // Verify socket file is cleaned up
        XCTAssertFalse(FileManager.default.fileExists(atPath: testSocketPath))
    }
    
    func testIPCServerErrorResponse() throws {
        let testSocketPath = "/tmp/test-ipc-error.sock"
        let server = IPCServer(socketPath: testSocketPath)
        let client = IPCClient(socketPath: testSocketPath, timeout: 2.0)
        
        // Clean up any existing socket
        try? FileManager.default.removeItem(atPath: testSocketPath)
        
        let errorMessage = "Test error message"
        let expectation = XCTestExpectation(description: "Error response sent")
        
        // Set up command handler that returns error
        server.commandHandler = { command, respond in
            respond(.error(message: errorMessage))
            expectation.fulfill()
        }
        
        // Start server
        try server.start()
        
        // Give server time to start
        Thread.sleep(forTimeInterval: 0.1)
        
        // Send command from client
        let response = try client.sendCommand(.hide)
        
        // Wait for response
        wait(for: [expectation], timeout: 3.0)
        
        // Verify error response
        XCTAssertEqual(response, .error(message: errorMessage))
        
        // Clean up
        server.stop()
    }
    
    func testMultipleClientConnections() throws {
        let testSocketPath = "/tmp/test-multiple-clients.sock"
        let server = IPCServer(socketPath: testSocketPath)
        
        // Clean up any existing socket
        try? FileManager.default.removeItem(atPath: testSocketPath)
        
        var commandCount = 0
        let expectation = XCTestExpectation(description: "Multiple commands received")
        expectation.expectedFulfillmentCount = 3
        
        // Set up command handler
        server.commandHandler = { command, respond in
            commandCount += 1
            respond(.success)
            expectation.fulfill()
        }
        
        // Start server
        try server.start()
        
        // Give server time to start
        Thread.sleep(forTimeInterval: 0.1)
        
        // Send commands from multiple clients concurrently
        DispatchQueue.concurrentPerform(iterations: 3) { index in
            let client = IPCClient(socketPath: testSocketPath, timeout: 2.0)
            do {
                let response = try client.sendCommand(.hide)
                XCTAssertEqual(response, .success)
            } catch {
                XCTFail("Client \(index) failed: \(error)")
            }
        }
        
        // Wait for all commands to be received
        wait(for: [expectation], timeout: 5.0)
        
        // Verify all commands were received
        XCTAssertEqual(commandCount, 3)
        
        // Clean up
        server.stop()
    }
    
    override func tearDown() {
        super.tearDown()
        
        // Clean up any test socket files
        let testPaths = [
            "/tmp/test-keybind-helper.sock",
            "/tmp/test-ipc-error.sock",
            "/tmp/test-multiple-clients.sock"
        ]
        
        for path in testPaths {
            try? FileManager.default.removeItem(atPath: path)
        }
    }
}