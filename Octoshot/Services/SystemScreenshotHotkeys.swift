import AppKit
import Carbon.HIToolbox
import Foundation
import OctoshotCore

/// Reads macOS system screenshot shortcuts from `com.apple.symbolichotkeys.plist`.
enum SystemScreenshotHotkeys {
    static let plistURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Preferences/com.apple.symbolichotkeys.plist")

    /// Symbolic hotkey IDs for built-in screenshot shortcuts.
    static let trackedIDs: [Int] = [28, 29, 30, 31, 184]

    struct Entry: Identifiable {
        let id: Int
        let title: String
        var enabled: Bool
        var binding: HotkeyBinding?
    }

    static func loadEntries() -> [Entry] {
        let root = NSDictionary(contentsOf: plistURL) as? [String: Any]
        let apple = root?["AppleSymbolicHotKeys"] as? [String: Any] ?? [:]
        return trackedIDs.map { id in
            let key = String(id)
            let dict = apple[key] as? [String: Any]
            let enabled = parseEnabled(dict?["enabled"])
            let binding = parseBinding(dict?["value"] as? [String: Any])
            return Entry(id: id, title: title(for: id), enabled: enabled, binding: binding)
        }
    }

    static func title(for id: Int) -> String {
        switch id {
        case 28: return "Save picture of screen (⌘⇧3)"
        case 29: return "Save picture of selection (⌘⇧4)"
        case 30: return "Screenshot & recording options (⌘⇧5)"
        case 31: return "Save picture of screen and window"
        case 184: return "Screenshot toolbar (macOS 15+)"
        default: return "Hotkey \(id)"
        }
    }

    /// Assign Octoshot capture shortcuts to match ⌘⇧3 / ⌘⇧4 / ⌘⇧5.
    @MainActor
    static func applyOctoshotTakeover(to settings: AppSettings = .shared) {
        settings.hotkeyFullscreen = .systemFullscreenCapture
        settings.hotkeyArea = .systemAreaCapture
        settings.hotkeyWindow = .systemScreenshotOptions
    }

    @MainActor
    static func conflicts(with settings: AppSettings = .shared) -> [Entry] {
        loadEntries().filter { entry in
            guard entry.enabled, let binding = entry.binding else { return false }
            return binding == settings.hotkeyFullscreen
                || binding == settings.hotkeyArea
                || binding == settings.hotkeyWindow
        }
    }

    static func openKeyboardSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension") {
            NSWorkspace.shared.open(url)
        } else if let url = URL(string: "x-apple.systempreferences:com.apple.preference.keyboard") {
            NSWorkspace.shared.open(url)
        }
    }

    private static let backupURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("Octoshot", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("symbolichotkeys-backup.plist")
    }()

    /// Disables tracked system screenshot hotkeys. Backs up the plist first.
    static func disableSystemScreenshotHotkeys() throws {
        guard FileManager.default.fileExists(atPath: plistURL.path) else {
            throw HotkeyPlistError.missingPlist
        }
        if !FileManager.default.fileExists(atPath: backupURL.path) {
            try FileManager.default.copyItem(at: plistURL, to: backupURL)
        }
        guard let data = try? Data(contentsOf: plistURL),
              var root = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else {
            throw HotkeyPlistError.parseFailed
        }
        var apple = root["AppleSymbolicHotKeys"] as? [String: Any] ?? [:]
        for id in trackedIDs {
            let key = String(id)
            guard var entry = apple[key] as? [String: Any] else { continue }
            entry["enabled"] = false
            apple[key] = entry
        }
        root["AppleSymbolicHotKeys"] = apple
        let out = try PropertyListSerialization.data(fromPropertyList: root, format: .xml, options: 0)
        try out.write(to: plistURL, options: .atomic)
        reloadSymbolicHotkeys()
    }

    static func restoreSystemScreenshotHotkeys() throws {
        guard FileManager.default.fileExists(atPath: backupURL.path) else {
            throw HotkeyPlistError.noBackup
        }
        if FileManager.default.fileExists(atPath: plistURL.path) {
            try FileManager.default.removeItem(at: plistURL)
        }
        try FileManager.default.copyItem(at: backupURL, to: plistURL)
        reloadSymbolicHotkeys()
    }

    static var hasBackup: Bool {
        FileManager.default.fileExists(atPath: backupURL.path)
    }

    private static func reloadSymbolicHotkeys() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        task.arguments = ["cfprefsd"]
        try? task.run()
        task.waitUntilExit()
    }

    private static func parseEnabled(_ value: Any?) -> Bool {
        switch value {
        case let b as Bool: return b
        case let n as Int: return n != 0
        case let s as String: return s != "0" && !s.isEmpty
        default: return false
        }
    }

    private static func parseBinding(_ value: [String: Any]?) -> HotkeyBinding? {
        guard let params = value?["parameters"] as? [Int], params.count >= 2 else { return nil }
        let modifiers = UInt32(truncatingIfNeeded: params[0])
        let keyCode = UInt32(truncatingIfNeeded: params[1])
        return HotkeyBinding(keyCode: keyCode, modifiers: modifiers)
    }

    enum HotkeyPlistError: LocalizedError {
        case missingPlist
        case parseFailed
        case noBackup

        var errorDescription: String? {
            switch self {
            case .missingPlist:
                return "Could not find com.apple.symbolichotkeys.plist."
            case .parseFailed:
                return "Could not parse symbolic hotkeys plist."
            case .noBackup:
                return "No saved backup of system screenshot shortcuts."
            }
        }
    }
}

extension HotkeyBinding {
    /// ⌘⇧3 — full screen (system default).
    static let systemFullscreenCapture = HotkeyBinding(
        keyCode: UInt32(kVK_ANSI_3),
        modifiers: UInt32(cmdKey | shiftKey)
    )
    /// ⌘⇧4 — selection / region.
    static let systemAreaCapture = HotkeyBinding(
        keyCode: UInt32(kVK_ANSI_4),
        modifiers: UInt32(cmdKey | shiftKey)
    )
    /// ⌘⇧5 — screenshot UI (window / options).
    static let systemScreenshotOptions = HotkeyBinding(
        keyCode: UInt32(kVK_ANSI_5),
        modifiers: UInt32(cmdKey | shiftKey)
    )
}
