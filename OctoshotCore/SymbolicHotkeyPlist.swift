import Foundation

/// Modifier masks stored in `AppleSymbolicHotKeys` plist `parameters[2]`.
/// See AppleSymbolicHotKeys documentation (Shift=0x20000, Command=0x100000, etc.).
public enum SymbolicHotkeyModifierMask {
    public static let shift: UInt32 = 131_072
    public static let control: UInt32 = 262_144
    public static let option: UInt32 = 524_288
    public static let command: UInt32 = 1_048_576

    public static func carbonModifiers(fromSymbolic mask: UInt32) -> UInt32 {
        var carbon: UInt32 = 0
        if mask & shift != 0 { carbon |= HotkeyCarbonModifiers.shift }
        if mask & control != 0 { carbon |= HotkeyCarbonModifiers.control }
        if mask & option != 0 { carbon |= HotkeyCarbonModifiers.option }
        if mask & command != 0 { carbon |= HotkeyCarbonModifiers.command }
        return carbon
    }
}

/// Built-in macOS screenshot symbolic hotkey IDs (see CGSHotKeys / community plist docs).
public enum ScreenshotSymbolicHotkeyID: Int, CaseIterable, Sendable {
    case saveFullScreenToFile = 28
    case copyFullScreenToClipboard = 29
    case saveSelectionToFile = 30
    case copySelectionToClipboard = 31
    case screenshotAndRecordingOptions = 184

    public static let trackedIDs: [Int] = allCases.map(\.rawValue)
}

public struct ResolvedSymbolicHotkey: Equatable, Sendable {
    public let id: Int
    public let enabled: Bool
    public let binding: HotkeyBinding
    /// `true` when the plist had no entry for this ID (system stock defaults apply).
    public let usesStockDefaults: Bool

    public init(id: Int, enabled: Bool, binding: HotkeyBinding, usesStockDefaults: Bool) {
        self.id = id
        self.enabled = enabled
        self.binding = binding
        self.usesStockDefaults = usesStockDefaults
    }
}

public enum SymbolicHotkeyPlist {
    private static let noKeySentinel = 65_535

    public static func parseEnabled(_ value: Any?) -> Bool {
        switch value {
        case let b as Bool:
            return b
        case let n as Int:
            return n != 0
        case let n as UInt:
            return n != 0
        case let s as String:
            return s != "0" && !s.isEmpty
        case nil:
            return true
        default:
            return false
        }
    }

    /// Parses `value.parameters` as `(ascii, keyCode, symbolicModifierMask)`.
    public static func binding(fromParameters parameters: [Int]) -> HotkeyBinding? {
        guard parameters.count >= 3 else { return nil }
        let ascii = parameters[0]
        let keyCode = UInt32(truncatingIfNeeded: parameters[1])
        let symbolicMask = UInt32(truncatingIfNeeded: parameters[2])
        if keyCode == noKeySentinel && ascii == noKeySentinel {
            return nil
        }
        let carbonMods = SymbolicHotkeyModifierMask.carbonModifiers(fromSymbolic: symbolicMask)
        return HotkeyBinding(keyCode: keyCode, modifiers: carbonMods)
    }

    /// Stock binding when the plist entry is missing or has no usable parameters.
    public static func stockBinding(for id: Int) -> HotkeyBinding? {
        switch id {
        case ScreenshotSymbolicHotkeyID.saveFullScreenToFile.rawValue:
            return .systemFullscreenCapture
        case ScreenshotSymbolicHotkeyID.copyFullScreenToClipboard.rawValue:
            return HotkeyBinding(
                keyCode: HotkeyKeyCode.ansi3,
                modifiers: HotkeyCarbonModifiers.command
                    | HotkeyCarbonModifiers.shift
                    | HotkeyCarbonModifiers.control
            )
        case ScreenshotSymbolicHotkeyID.saveSelectionToFile.rawValue:
            return .systemAreaCapture
        case ScreenshotSymbolicHotkeyID.copySelectionToClipboard.rawValue:
            return HotkeyBinding(
                keyCode: HotkeyKeyCode.ansi4,
                modifiers: HotkeyCarbonModifiers.command
                    | HotkeyCarbonModifiers.shift
                    | HotkeyCarbonModifiers.control
            )
        case ScreenshotSymbolicHotkeyID.screenshotAndRecordingOptions.rawValue:
            return .systemScreenshotOptions
        default:
            return nil
        }
    }

    public static func resolveEntry(id: Int, plistEntry: [String: Any]?) -> ResolvedSymbolicHotkey? {
        guard let stock = stockBinding(for: id) else { return nil }
        guard let plistEntry else {
            return ResolvedSymbolicHotkey(id: id, enabled: true, binding: stock, usesStockDefaults: true)
        }
        let enabled = parseEnabled(plistEntry["enabled"])
        let value = plistEntry["value"] as? [String: Any]
        let params = value?["parameters"] as? [Int] ?? []
        let binding = binding(fromParameters: params) ?? stock
        return ResolvedSymbolicHotkey(id: id, enabled: enabled, binding: binding, usesStockDefaults: false)
    }

    public static func loadScreenshotEntries(from appleSymbolicHotKeys: [String: Any]) -> [ResolvedSymbolicHotkey] {
        ScreenshotSymbolicHotkeyID.trackedIDs.compactMap { id in
            let key = String(id)
            let entry = appleSymbolicHotKeys[key] as? [String: Any]
            return resolveEntry(id: id, plistEntry: entry)
        }
    }

    public static func loadScreenshotEntries(fromPlistRoot root: [String: Any]) -> [ResolvedSymbolicHotkey] {
        let apple = root["AppleSymbolicHotKeys"] as? [String: Any] ?? [:]
        return loadScreenshotEntries(from: apple)
    }

    /// Enabled system screenshot shortcuts that collide with any Octoshot capture hotkey.
    public static func conflictingScreenshotEntries(
        octoshot: OctoshotHotkeySet,
        entries: [ResolvedSymbolicHotkey]
    ) -> [ResolvedSymbolicHotkey] {
        let octo = Set([octoshot.area, octoshot.window, octoshot.fullscreen])
        return entries.filter { $0.enabled && octo.contains($0.binding) }
    }

    public static func conflicts(
        octoshot: OctoshotHotkeySet,
        appleSymbolicHotKeys: [String: Any]
    ) -> [ResolvedSymbolicHotkey] {
        let entries = loadScreenshotEntries(from: appleSymbolicHotKeys)
        return conflictingScreenshotEntries(octoshot: octoshot, entries: entries)
    }

    public static func conflicts(
        octoshot: OctoshotHotkeySet,
        plistRoot: [String: Any]
    ) -> [ResolvedSymbolicHotkey] {
        conflictingScreenshotEntries(
            octoshot: octoshot,
            entries: loadScreenshotEntries(fromPlistRoot: plistRoot)
        )
    }

    /// Whether a candidate binding is already used by another Octoshot hotkey or an enabled system screenshot shortcut.
    public static func recordingConflict(
        candidate: HotkeyBinding,
        replacing: String,
        octoshot: OctoshotHotkeySet,
        systemEntries: [ResolvedSymbolicHotkey]
    ) -> String? {
        if !HotkeyCarbonModifiers.requiresAnyModifier(candidate.modifiers) {
            return "modifier_required"
        }
        for (label, binding) in octoshot.allBindings where label != replacing && binding == candidate {
            return "octoshot_duplicate"
        }
        if systemEntries.contains(where: { $0.enabled && $0.binding == candidate }) {
            return "system_duplicate"
        }
        return nil
    }
}

// MARK: - Backup / disable / restore (file-based, testable)

public struct SymbolicHotkeyIDBackup {
    public enum State {
        case missingFromPlist
        case entry([String: Any])
    }

    public var states: [String: State]

    public init(states: [String: State] = [:]) {
        self.states = states
    }
}

public enum SymbolicHotkeyPlistEditor {
    public static let backupVersionKey = "OctoshotSymbolicHotkeyBackupVersion"
    public static let backupEntriesKey = "entries"
    public static let backupMissingKey = "missing"
    public static let backupEntryKey = "entry"

    public static func decodeBackup(from data: Data) throws -> SymbolicHotkeyIDBackup {
        let root = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        guard let entries = root?[backupEntriesKey] as? [String: Any] else {
            return SymbolicHotkeyIDBackup()
        }
        var states: [String: SymbolicHotkeyIDBackup.State] = [:]
        for (id, value) in entries {
            guard let dict = value as? [String: Any] else { continue }
            if dict[backupMissingKey] as? Bool == true {
                states[id] = .missingFromPlist
            } else if let entry = dict[backupEntryKey] as? [String: Any] {
                states[id] = .entry(entry)
            }
        }
        return SymbolicHotkeyIDBackup(states: states)
    }

    public static func encodeBackup(_ backup: SymbolicHotkeyIDBackup) throws -> Data {
        var entries: [String: Any] = [:]
        for (id, state) in backup.states {
            switch state {
            case .missingFromPlist:
                entries[id] = [backupMissingKey: true]
            case .entry(let dict):
                entries[id] = [backupEntryKey: dict]
            }
        }
        let root: [String: Any] = [
            backupVersionKey: 1,
            backupEntriesKey: entries,
        ]
        return try PropertyListSerialization.data(fromPropertyList: root, format: .xml, options: 0)
    }

    /// Records original plist fragments for IDs not yet present in `backup`.
    public static func captureBackup(
        ids: [Int],
        appleSymbolicHotKeys: [String: Any],
        into backup: SymbolicHotkeyIDBackup
    ) -> SymbolicHotkeyIDBackup {
        var result = backup
        for id in ids {
            let key = String(id)
            guard result.states[key] == nil else { continue }
            if let entry = appleSymbolicHotKeys[key] as? [String: Any] {
                result.states[key] = .entry(entry)
            } else {
                result.states[key] = .missingFromPlist
            }
        }
        return result
    }

    public static func disableScreenshotHotkeys(
        ids: [Int],
        in root: [String: Any]
    ) -> [String: Any] {
        var updated = root
        var apple = updated["AppleSymbolicHotKeys"] as? [String: Any] ?? [:]
        for id in ids {
            let key = String(id)
            var entry = apple[key] as? [String: Any]
            if entry == nil {
                guard let stock = SymbolicHotkeyPlist.stockBinding(for: id) else { continue }
                entry = stockPlistEntry(for: stock)
            }
            entry?["enabled"] = false
            apple[key] = entry
        }
        updated["AppleSymbolicHotKeys"] = apple
        return updated
    }

    public static func restore(
        backup: SymbolicHotkeyIDBackup,
        into root: [String: Any]
    ) -> [String: Any] {
        var updated = root
        var apple = updated["AppleSymbolicHotKeys"] as? [String: Any] ?? [:]
        for (id, state) in backup.states {
            switch state {
            case .missingFromPlist:
                apple.removeValue(forKey: id)
            case .entry(let entry):
                apple[id] = entry
            }
        }
        updated["AppleSymbolicHotKeys"] = apple
        return updated
    }

    private static func stockPlistEntry(for binding: HotkeyBinding) -> [String: Any] {
        let symbolicMask = symbolicMask(fromCarbon: binding.modifiers)
        let ascii = asciiForKeyCode(binding.keyCode)
        return [
            "enabled": true,
            "value": [
                "type": "standard",
                "parameters": [ascii, Int(binding.keyCode), Int(symbolicMask)],
            ],
        ]
    }

    private static func asciiForKeyCode(_ keyCode: UInt32) -> Int {
        switch keyCode {
        case HotkeyKeyCode.ansi3: return 51
        case HotkeyKeyCode.ansi4: return 52
        case HotkeyKeyCode.ansi5: return 53
        default: return 65_535
        }
    }

    private static func symbolicMask(fromCarbon carbon: UInt32) -> UInt32 {
        var mask: UInt32 = 0
        if carbon & HotkeyCarbonModifiers.shift != 0 { mask |= SymbolicHotkeyModifierMask.shift }
        if carbon & HotkeyCarbonModifiers.control != 0 { mask |= SymbolicHotkeyModifierMask.control }
        if carbon & HotkeyCarbonModifiers.option != 0 { mask |= SymbolicHotkeyModifierMask.option }
        if carbon & HotkeyCarbonModifiers.command != 0 { mask |= SymbolicHotkeyModifierMask.command }
        return mask
    }
}
