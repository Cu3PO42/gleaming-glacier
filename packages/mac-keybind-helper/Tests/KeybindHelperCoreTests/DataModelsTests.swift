import XCTest
@testable import KeybindHelperCore

final class DataModelsTests: XCTestCase {
    
    func testKeyModifiersInitialization() {
        let modifiers = KeyModifiers(shift: true, ctrl: false, alt: true, `super`: false)
        
        XCTAssertTrue(modifiers.shift)
        XCTAssertFalse(modifiers.ctrl)
        XCTAssertTrue(modifiers.alt)
        XCTAssertFalse(modifiers.`super`)
    }
    
    func testKeyModifiersDefaultInitialization() {
        let modifiers = KeyModifiers()
        
        XCTAssertFalse(modifiers.shift)
        XCTAssertFalse(modifiers.ctrl)
        XCTAssertFalse(modifiers.alt)
        XCTAssertFalse(modifiers.`super`)
    }
    
    func testKeyCombinationDisplayString() {
        let modifiers = KeyModifiers(shift: true, ctrl: true, alt: false, `super`: true)
        let keyCombo = KeyCombination(key: "a", modifiers: modifiers)
        
        let displayString = keyCombo.displayString
        XCTAssertTrue(displayString.contains("⌘")) // super
        XCTAssertTrue(displayString.contains("⌃")) // ctrl
        XCTAssertTrue(displayString.contains("⇧")) // shift
        XCTAssertFalse(displayString.contains("⌥")) // alt should not be present
        XCTAssertTrue(displayString.contains("A")) // key should be uppercase
    }
    
    func testKeyCombinationDisplayStringNoModifiers() {
        let keyCombo = KeyCombination(key: "x")
        XCTAssertEqual(keyCombo.displayString, "X")
    }
    
    func testKeybindingInitialization() {
        let keyCombo = KeyCombination(key: "s", modifiers: KeyModifiers(ctrl: true))
        let binding = Keybinding(key: keyCombo, name: "Save", description: "Save current file")
        
        XCTAssertEqual(binding.key, keyCombo)
        XCTAssertEqual(binding.name, "Save")
        XCTAssertEqual(binding.description, "Save current file")
    }
    
    func testKeymapInitialization() {
        let binding = Keybinding(
            key: KeyCombination(key: "n", modifiers: KeyModifiers(ctrl: true)),
            name: "New",
            description: "Create new file"
        )
        
        let keymap = Keymap(
            parentId: "",
            name: "Main Keymap",
            description: "Primary keybindings",
            binds: [binding]
        )
        
        XCTAssertEqual(keymap.parentId, "")
        XCTAssertEqual(keymap.name, "Main Keymap")
        XCTAssertEqual(keymap.description, "Primary keybindings")
        XCTAssertEqual(keymap.binds.count, 1)
        XCTAssertEqual(keymap.binds.first, binding)
    }
    
    func testKeymapConfigurationInitialization() {
        let keymap = Keymap(name: "Test", description: "Test keymap")
        let config = KeymapConfiguration(maps: ["test": keymap])
        
        XCTAssertEqual(config.maps.count, 1)
        XCTAssertEqual(config.keymap(withId: "test"), keymap)
        XCTAssertNil(config.keymap(withId: "nonexistent"))
        XCTAssertTrue(config.keymapIds.contains("test"))
    }
}