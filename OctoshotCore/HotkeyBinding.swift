import Foundation

/// Carbon-style key binding used by `RegisterEventHotKey` (key code + modifier flags).
public struct HotkeyBinding: Codable, Equatable, Hashable, Sendable {
    public var keyCode: UInt32
    public var modifiers: UInt32

    public init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }
}

/// Carbon `Events.h` modifier masks (for global hotkey registration).
public enum HotkeyCarbonModifiers {
    public static let command: UInt32 = 256
    public static let shift: UInt32 = 512
    public static let option: UInt32 = 2048
    public static let control: UInt32 = 4096

    public static func containsCommand(_ flags: UInt32) -> Bool { flags & command != 0 }
    public static func containsShift(_ flags: UInt32) -> Bool { flags & shift != 0 }
    public static func containsOption(_ flags: UInt32) -> Bool { flags & option != 0 }
    public static func containsControl(_ flags: UInt32) -> Bool { flags & control != 0 }

    public static func requiresAnyModifier(_ flags: UInt32) -> Bool {
        containsCommand(flags) || containsShift(flags) || containsOption(flags) || containsControl(flags)
    }
}

/// Virtual key codes for common keys (ANSI layout).
public enum HotkeyKeyCode {
    public static let ansi3: UInt32 = 20
    public static let ansi4: UInt32 = 21
    public static let ansi5: UInt32 = 23
    public static let escape: UInt32 = 53
}

public extension HotkeyBinding {
    static let systemFullscreenCapture = HotkeyBinding(
        keyCode: HotkeyKeyCode.ansi3,
        modifiers: HotkeyCarbonModifiers.command | HotkeyCarbonModifiers.shift
    )
    static let systemAreaCapture = HotkeyBinding(
        keyCode: HotkeyKeyCode.ansi4,
        modifiers: HotkeyCarbonModifiers.command | HotkeyCarbonModifiers.shift
    )
    static let systemScreenshotOptions = HotkeyBinding(
        keyCode: HotkeyKeyCode.ansi5,
        modifiers: HotkeyCarbonModifiers.command | HotkeyCarbonModifiers.shift
    )

    static let areaDefault = systemAreaCapture
    static let windowDefault = systemScreenshotOptions
    static let fullscreenDefault = systemFullscreenCapture
}

/// The three global capture shortcuts configured in Octoshot settings.
public struct OctoshotHotkeySet: Equatable, Sendable {
    public var area: HotkeyBinding
    public var window: HotkeyBinding
    public var fullscreen: HotkeyBinding

    public init(area: HotkeyBinding, window: HotkeyBinding, fullscreen: HotkeyBinding) {
        self.area = area
        self.window = window
        self.fullscreen = fullscreen
    }

    public var allBindings: [(label: String, binding: HotkeyBinding)] {
        [
            ("area", area),
            ("window", window),
            ("fullscreen", fullscreen),
        ]
    }

    /// Returns bindings that appear more than once among Octoshot hotkeys.
    public func duplicateBindings() -> [HotkeyBinding] {
        let bindings = [area, window, fullscreen]
        var seen: Set<HotkeyBinding> = []
        var duplicates: Set<HotkeyBinding> = []
        for binding in bindings {
            if seen.contains(binding) {
                duplicates.insert(binding)
            } else {
                seen.insert(binding)
            }
        }
        return Array(duplicates)
    }
}
