import XCTest
@testable import KeybindHelperCore
@testable import KeybindHelperDaemon

/// Integration tests for daemon command handling
final class DaemonIntegrationTests: XCTestCase {
    
    var testConfigPath: String!
    
    override func setUp() {
        super.setUp()
        
        // Create test configuration file
        testConfigPath = createTestConfiguration()
    }
    
    override func tearDown() {
        // Clean up test file
        if let path = testConfigPath {
            try? FileManager.default.removeItem(atPath: path)
        }
        super.tearDown()
    }
    
    func testShowCommandWithValidConfiguration() {
        // Load configuration using ConfigurationParser directly
        do {
            let configuration = try ConfigurationParser.parseConfiguration(from: testConfigPath)
            
            // Get keymap
            let keymap = configuration.keymap(withId: "main")
            XCTAssertNotNil(keymap, "Main keymap should exist")
            XCTAssertEqual(keymap?.name, "Test Main Keymap")
            XCTAssertEqual(keymap?.binds.count, 2)
        } catch {
            XCTFail("Configuration should load successfully: \(error)")
        }
    }
    
    func testShowCommandWithInvalidMapId() {
        // Load configuration using ConfigurationParser directly
        do {
            let configuration = try ConfigurationParser.parseConfiguration(from: testConfigPath)
            
            // Try to get non-existent keymap
            let keymap = configuration.keymap(withId: "nonexistent")
            XCTAssertNil(keymap, "Non-existent keymap should return nil")
        } catch {
            XCTFail("Configuration should load successfully: \(error)")
        }
    }
    
    func testConfigurationLoadingDifferentFiles() {
        // Load initial configuration using ConfigurationParser directly
        do {
            let configuration1 = try ConfigurationParser.parseConfiguration(from: testConfigPath)
            XCTAssertNotNil(configuration1.keymap(withId: "main"), "First config should have main keymap")
            
            // Create a second test configuration
            let secondConfigPath = createSecondTestConfiguration()
            
            // Load second configuration
            let configuration2 = try ConfigurationParser.parseConfiguration(from: secondConfigPath)
            XCTAssertNotNil(configuration2.keymap(withId: "secondary"), "Second config should have secondary keymap")
            XCTAssertNil(configuration2.keymap(withId: "main"), "Second config should not have main keymap")
            
            // Clean up second config
            try? FileManager.default.removeItem(atPath: secondConfigPath)
        } catch {
            XCTFail("Configuration loading should succeed: \(error)")
        }
    }
    
    func testSwiftUIWindowControllerIntegration() {
        // Load configuration using ConfigurationParser directly
        do {
            let configuration = try ConfigurationParser.parseConfiguration(from: testConfigPath)
            
            guard let keymap = configuration.keymap(withId: "main") else {
                XCTFail("Main keymap should exist")
                return
            }
            
            // Test window controller operations
            let windowController = SwiftUIOverlayWindowController()
            XCTAssertNotNil(windowController.window, "Window controller should have a window")
            
            // Note: We can't actually test window showing in unit tests without a GUI environment
            // But we can test that the methods don't crash
            windowController.updateKeymap(keymap)
            XCTAssertNotNil(windowController.window?.contentView, "Window should have content view after keymap update")
        } catch {
            XCTFail("Configuration should load successfully: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createSecondTestConfiguration() -> String {
        let testConfig = """
        {
            "maps": {
                "secondary": {
                    "parentId": "",
                    "name": "Secondary Test Keymap",
                    "description": "Secondary test keymap",
                    "binds": [
                        {
                            "key": {
                                "key": "s",
                                "modifiers": {
                                    "shift": false,
                                    "ctrl": true,
                                    "alt": false,
                                    "super": false
                                }
                            },
                            "name": "Secondary Action",
                            "description": "Secondary test keybinding"
                        }
                    ]
                }
            }
        }
        """
        
        let tempDir = NSTemporaryDirectory()
        let testConfigPath = (tempDir as NSString).appendingPathComponent("second-test-config-\(UUID().uuidString).json")
        
        do {
            try testConfig.write(toFile: testConfigPath, atomically: true, encoding: .utf8)
            return testConfigPath
        } catch {
            XCTFail("Failed to create second test configuration file: \(error)")
            return ""
        }
    }
    
    private func createTestConfiguration() -> String {
        let testConfig = """
        {
            "maps": {
                "main": {
                    "parentId": "",
                    "name": "Test Main Keymap",
                    "description": "Test keymap for integration tests",
                    "binds": [
                        {
                            "key": {
                                "key": "t",
                                "modifiers": {
                                    "shift": false,
                                    "ctrl": true,
                                    "alt": false,
                                    "super": false
                                }
                            },
                            "name": "Test Action",
                            "description": "Test keybinding"
                        },
                        {
                            "key": {
                                "key": "q",
                                "modifiers": {
                                    "shift": false,
                                    "ctrl": false,
                                    "alt": false,
                                    "super": true
                                }
                            },
                            "name": "Quit",
                            "description": "Quit application"
                        }
                    ]
                }
            }
        }
        """
        
        let tempDir = NSTemporaryDirectory()
        let testConfigPath = (tempDir as NSString).appendingPathComponent("test-config-\(UUID().uuidString).json")
        
        do {
            try testConfig.write(toFile: testConfigPath, atomically: true, encoding: .utf8)
            return testConfigPath
        } catch {
            XCTFail("Failed to create test configuration file: \(error)")
            return ""
        }
    }
}

