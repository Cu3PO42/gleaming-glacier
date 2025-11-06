import Foundation

// MARK: - Core Data Models

/// Represents a set of key modifiers
public struct KeyModifiers: Codable, Equatable {
    public let shift: Bool
    public let ctrl: Bool
    public let alt: Bool
    public let `super`: Bool
    
    public init(shift: Bool = false, ctrl: Bool = false, alt: Bool = false, `super`: Bool = false) {
        self.shift = shift
        self.ctrl = ctrl
        self.alt = alt
        self.`super` = `super`
    }
}

/// Represents a key combination with modifiers
public struct KeyCombination: Codable, Equatable {
    public let key: String
    public let modifiers: KeyModifiers
    
    public init(key: String, modifiers: KeyModifiers = KeyModifiers()) {
        self.key = key
        self.modifiers = modifiers
    }
    
    /// Formatted display string for the key combination
    public var displayString: String {
        var components: [String] = []
        
        if modifiers.`super` {
            components.append("⌘")
        }
        if modifiers.ctrl {
            components.append("⌃")
        }
        if modifiers.alt {
            components.append("⌥")
        }
        if modifiers.shift {
            components.append("⇧")
        }
        
        components.append(formattedKey)
        return components.joined()
    }
    
    /// Formatted key with configurable display mappings
    private var formattedKey: String {
        let config = KeyDisplayConfigurationManager.loadConfiguration()
        let lowercaseKey = key.lowercased()
        
        if let mapping = config.keyMappings[lowercaseKey] {
            return mapping
        }
        
        return key.uppercased()
    }
}

/// Represents a single keybinding entry
public struct Keybinding: Codable, Equatable {
    public let key: KeyCombination
    public let name: String
    public let description: String
    
    public init(key: KeyCombination, name: String, description: String) {
        self.key = key
        self.name = name
        self.description = description
    }
}

/// Represents a keymap with its bindings
public struct Keymap: Codable, Equatable {
    public let parentId: String
    public let name: String
    public let description: String
    public let binds: [Keybinding]
    
    public init(parentId: String = "", name: String, description: String, binds: [Keybinding] = []) {
        self.parentId = parentId
        self.name = name
        self.description = description
        self.binds = binds
    }
}

/// Container for all keymaps in a configuration
public struct KeymapConfiguration: Codable, Equatable {
    public let maps: [String: Keymap]
    
    public init(maps: [String: Keymap] = [:]) {
        self.maps = maps
    }
    
    /// Get a keymap by its ID
    public func keymap(withId id: String) -> Keymap? {
        return maps[id]
    }
    
    /// Get all keymap IDs
    public var keymapIds: [String] {
        return Array(maps.keys)
    }
}