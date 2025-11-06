import XCTest
@testable import KeybindHelperCore
@testable import KeybindHelperDaemon

final class OverlayWindowTests: XCTestCase {
    
    func testSwiftUIOverlayWindowControllerCreation() {
        let windowController = SwiftUIOverlayWindowController()
        
        // Test window controller and window configuration
        XCTAssertNotNil(windowController.window)
        
        if let window = windowController.window {
            XCTAssertEqual(window.level, .floating)
            XCTAssertFalse(window.isOpaque)
            XCTAssertEqual(window.backgroundColor, .clear)
            XCTAssertTrue(window.hasShadow)
            XCTAssertFalse(window.ignoresMouseEvents)
        }
    }
    
    func testSwiftUIOverlayWindowControllerKeymap() {
        let windowController = SwiftUIOverlayWindowController()
        let testKeymap = createTestKeymap()
        
        // Test updating keymap
        windowController.updateKeymap(testKeymap)
        
        // Test that window content view is set
        XCTAssertNotNil(windowController.window?.contentView)
        
        // Test window visibility methods
        windowController.window?.makeKeyAndOrderFront(nil)
        XCTAssertTrue(windowController.window?.isVisible ?? false)
        
        windowController.window?.orderOut(nil)
        XCTAssertFalse(windowController.window?.isVisible ?? true)
    }
    
    // MARK: - Helper Methods
    
    private func createTestKeymap(name: String = "Test Keymap") -> Keymap {
        let keyCombination = KeyCombination(
            key: "a",
            modifiers: KeyModifiers(shift: false, ctrl: true, alt: false, super: false)
        )
        
        let binding = Keybinding(
            key: keyCombination,
            name: "Test Action",
            description: "A test keybinding action"
        )
        
        return Keymap(
            id: "test-keymap",
            name: name,
            description: "A test keymap for unit testing",
            bindings: [binding]
        )
    }
}