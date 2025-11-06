import XCTest
@testable import KeybindHelperCore

final class ConfigurationParserTests: XCTestCase {
    
    func testValidConfigurationParsing() throws {
        let jsonString = """
        {
          "maps": {
            "main": {
              "parentId": "",
              "name": "Main Keymap",
              "description": "Primary keybindings",
              "binds": [
                {
                  "key": {
                    "key": "a",
                    "modifiers": {
                      "shift": false,
                      "ctrl": true,
                      "alt": false,
                      "super": false
                    }
                  },
                  "name": "Action A",
                  "description": "Perform action A"
                }
              ]
            }
          }
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let config = try ConfigurationParser.parseConfiguration(from: data)
        
        XCTAssertEqual(config.maps.count, 1)
        
        let mainKeymap = config.keymap(withId: "main")
        XCTAssertNotNil(mainKeymap)
        XCTAssertEqual(mainKeymap?.name, "Main Keymap")
        XCTAssertEqual(mainKeymap?.description, "Primary keybindings")
        XCTAssertEqual(mainKeymap?.binds.count, 1)
        
        let binding = mainKeymap?.binds.first
        XCTAssertEqual(binding?.key.key, "a")
        XCTAssertTrue(binding?.key.modifiers.ctrl ?? false)
        XCTAssertFalse(binding?.key.modifiers.shift ?? true)
        XCTAssertEqual(binding?.name, "Action A")
        XCTAssertEqual(binding?.description, "Perform action A")
    }
    
    func testEmptyConfigurationValidation() throws {
        let jsonString = """
        {
          "maps": {}
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let config = try ConfigurationParser.parseConfiguration(from: data)
        
        XCTAssertEqual(config.maps.count, 0)
    }
    
    func testInvalidJSONFormat() {
        let invalidJSON = "{ invalid json }".data(using: .utf8)!
        
        XCTAssertThrowsError(try ConfigurationParser.parseConfiguration(from: invalidJSON)) { error in
            XCTAssertTrue(error is ConfigurationError)
            if case ConfigurationError.decodingFailed = error {
                // Expected error type
            } else {
                XCTFail("Expected decodingFailed error")
            }
        }
    }
    
    func testMissingMapsKey() {
        let jsonString = """
        {
          "other": "data"
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        
        XCTAssertThrowsError(try ConfigurationParser.parseConfiguration(from: data)) { error in
            if case ConfigurationError.decodingFailed = error {
                // Expected error type - missing 'maps' key will cause decoding to fail
            } else {
                XCTFail("Expected decodingFailed error")
            }
        }
    }
    
    func testKeymapWithEmptyName() throws {
        let jsonString = """
        {
          "maps": {
            "test": {
              "parentId": "",
              "name": "",
              "description": "Test keymap",
              "binds": []
            }
          }
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let config = try ConfigurationParser.parseConfiguration(from: data)
        
        let testKeymap = config.keymap(withId: "test")
        XCTAssertNotNil(testKeymap)
        XCTAssertEqual(testKeymap?.name, "")
    }
    
    func testKeymapWithInvalidParentReference() throws {
        let jsonString = """
        {
          "maps": {
            "child": {
              "parentId": "nonexistent",
              "name": "Child Keymap",
              "description": "Child keymap",
              "binds": []
            }
          }
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let config = try ConfigurationParser.parseConfiguration(from: data)
        
        let childKeymap = config.keymap(withId: "child")
        XCTAssertNotNil(childKeymap)
        XCTAssertEqual(childKeymap?.parentId, "nonexistent")
    }
    
    func testParseConfigurationFromFileSuccess() {
        let jsonString = """
        {
          "maps": {
            "test": {
              "parentId": "",
              "name": "Test",
              "description": "Test keymap",
              "binds": []
            }
          }
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        
        // Create a temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-config.json")
        try! data.write(to: tempURL)
        
        do {
            let config = try ConfigurationParser.parseConfiguration(from: tempURL.path)
            XCTAssertEqual(config.maps.count, 1)
        } catch {
            XCTFail("Expected success, got error: \(error)")
        }
        
        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    func testParseConfigurationFileNotFound() {
        XCTAssertThrowsError(try ConfigurationParser.parseConfiguration(from: "/nonexistent/path.json")) { error in
            if case ConfigurationError.fileNotFound = error {
                // Expected error type
            } else {
                XCTFail("Expected fileNotFound error")
            }
        }
    }
}