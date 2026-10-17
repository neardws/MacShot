import AppKit
import Foundation
import OctoshotCore

/// Reads and updates macOS system screenshot shortcuts in `com.apple.symbolichotkeys`.
enum SystemScreenshotHotkeys {
    static let plistURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Preferences/com.apple.symbolichotkeys.plist")

    static let trackedIDs = ScreenshotSymbolicHotkeyID.trackedIDs

    struct Entry: Identifiable {
        let id: Int
        let title: String
        var enabled: Bool
        var binding: HotkeyBinding
        var usesStockDefaults: Bool
    }

    static func loadEntries() -> [Entry] {
        let root = loadPlistRoot()
        return SymbolicHotkeyPlist.loadScreenshotEntries(fromPlistRoot: root).map { resolved in
            Entry(
                id: resolved.id,
                title: title(for: resolved.id),
                enabled: resolved.enabled,
                binding: resolved.binding,
                usesStockDefaults: resolved.usesStockDefaults
            )
        }
    }

    static func title(for id: Int) -> String {
        OctoshotL10n.systemScreenshotHotkeyTitle(id)
    }

    @MainActor
    static func applyOctoshotTakeover(to settings: AppSettings = .shared) {
        settings.hotkeyFullscreen = .systemFullscreenCapture
        settings.hotkeyArea = .systemAreaCapture
        settings.hotkeyWindow = .systemScreenshotOptions
    }

    @MainActor
    static func octoshotHotkeySet(from settings: AppSettings = .shared) -> OctoshotHotkeySet {
        OctoshotHotkeySet(
            area: settings.hotkeyArea,
            window: settings.hotkeyWindow,
            fullscreen: settings.hotkeyFullscreen
        )
    }

    @MainActor
    static func conflicts(with settings: AppSettings = .shared) -> [Entry] {
        let root = loadPlistRoot()
        let octo = octoshotHotkeySet(from: settings)
        return SymbolicHotkeyPlist.conflicts(octoshot: octo, plistRoot: root).map { resolved in
            Entry(
                id: resolved.id,
                title: title(for: resolved.id),
                enabled: resolved.enabled,
                binding: resolved.binding,
                usesStockDefaults: resolved.usesStockDefaults
            )
        }
    }

    @MainActor
    static func hasConflicts(with settings: AppSettings = .shared) -> Bool {
        !conflicts(with: settings).isEmpty
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
        return dir.appendingPathComponent("symbolichotkeys-id-backup.plist")
    }()

    static var hasBackup: Bool {
        guard let data = try? Data(contentsOf: backupURL),
              let backup = try? SymbolicHotkeyPlistEditor.decodeBackup(from: data)
        else { return false }
        return !backup.states.isEmpty
    }

    /// Disables tracked system screenshot hotkeys. Backs up only affected IDs (never replaces the whole plist).
    static func disableSystemScreenshotHotkeys() throws {
        var root = loadPlistRoot()
        let apple = root["AppleSymbolicHotKeys"] as? [String: Any] ?? [:]

        var backup = loadBackup() ?? SymbolicHotkeyIDBackup()
        backup = SymbolicHotkeyPlistEditor.captureBackup(
            ids: trackedIDs,
            appleSymbolicHotKeys: apple,
            into: backup
        )
        try saveBackup(backup)

        root = SymbolicHotkeyPlistEditor.disableScreenshotHotkeys(ids: trackedIDs, in: root)
        try writePlistRoot(root)
        reloadSymbolicHotkeys()
    }

    static func restoreSystemScreenshotHotkeys() throws {
        guard let backup = loadBackup(), !backup.states.isEmpty else {
            throw HotkeyPlistError.noBackup
        }
        var root = loadPlistRoot()
        root = SymbolicHotkeyPlistEditor.restore(backup: backup, into: root)
        try writePlistRoot(root)
        try? FileManager.default.removeItem(at: backupURL)
        reloadSymbolicHotkeys()
    }

    static func resolvedSystemEntries() -> [ResolvedSymbolicHotkey] {
        SymbolicHotkeyPlist.loadScreenshotEntries(fromPlistRoot: loadPlistRoot())
    }

    // MARK: - Plist IO

    static func loadPlistRoot() -> [String: Any] {
        guard let data = try? Data(contentsOf: plistURL),
              let root = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else {
            return ["AppleSymbolicHotKeys": [:]]
        }
        return root
    }

    private static func writePlistRoot(_ root: [String: Any]) throws {
        let dir = plistURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let out = try PropertyListSerialization.data(fromPropertyList: root, format: .xml, options: 0)
        try out.write(to: plistURL, options: .atomic)
        CFPreferencesAppSynchronize("com.apple.symbolichotkeys" as CFString)
    }

    private static func loadBackup() -> SymbolicHotkeyIDBackup? {
        guard let data = try? Data(contentsOf: backupURL) else { return nil }
        return try? SymbolicHotkeyPlistEditor.decodeBackup(from: data)
    }

    private static func saveBackup(_ backup: SymbolicHotkeyIDBackup) throws {
        let data = try SymbolicHotkeyPlistEditor.encodeBackup(backup)
        try data.write(to: backupURL, options: .atomic)
    }

    /// Applies symbolic hotkey changes without logging out (defaults read + activateSettings).
    static func reloadSymbolicHotkeys() {
        let read = Process()
        read.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        read.arguments = ["read", "com.apple.symbolichotkeys"]
        try? read.run()
        read.waitUntilExit()

        let activatePath = "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"
        guard FileManager.default.isExecutableFile(atPath: activatePath) else { return }
        let activate = Process()
        activate.executableURL = URL(fileURLWithPath: activatePath)
        activate.arguments = ["-u"]
        try? activate.run()
        activate.waitUntilExit()
    }

    enum HotkeyPlistError: LocalizedError {
        case missingPlist
        case parseFailed
        case noBackup

        var errorDescription: String? {
            switch self {
            case .missingPlist:
                return OctoshotL10n.systemHotkeyMissingPlist
            case .parseFailed:
                return OctoshotL10n.systemHotkeyParseFailed
            case .noBackup:
                return OctoshotL10n.systemHotkeyNoBackup
            }
        }
    }
}
