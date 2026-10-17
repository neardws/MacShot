import XCTest
@testable import OctoshotCore

final class SymbolicHotkeyPlistTests: XCTestCase {
    func testParsesScreenshotParametersOrder() {
        // ⌘⇧3 — parameters (ascii, keyCode, symbolicModifiers)
        let binding = SymbolicHotkeyPlist.binding(fromParameters: [51, 20, 1_179_648])
        XCTAssertEqual(binding, .systemFullscreenCapture)
    }

    func testParsesCtrlShiftCmd4() {
        let binding = SymbolicHotkeyPlist.binding(fromParameters: [52, 21, 1_441_792])
        XCTAssertEqual(
            binding,
            HotkeyBinding(
                keyCode: HotkeyKeyCode.ansi4,
                modifiers: HotkeyCarbonModifiers.command
                    | HotkeyCarbonModifiers.shift
                    | HotkeyCarbonModifiers.control
            )
        )
    }

    func testMissingPlistEntryUsesStockDefaultsAndEnabled() {
        let resolved = SymbolicHotkeyPlist.resolveEntry(id: 30, plistEntry: nil)
        XCTAssertEqual(resolved?.enabled, true)
        XCTAssertEqual(resolved?.binding, .systemAreaCapture)
        XCTAssertEqual(resolved?.usesStockDefaults, true)
    }

    func testDetectsConflictWhenStockDefaultsApply() {
        let octo = OctoshotHotkeySet(
            area: .systemAreaCapture,
            window: .systemScreenshotOptions,
            fullscreen: .systemFullscreenCapture
        )
        let conflicts = SymbolicHotkeyPlist.conflicts(octoshot: octo, appleSymbolicHotKeys: [:])
        XCTAssertEqual(conflicts.count, 3)
        XCTAssertTrue(conflicts.contains { $0.id == 30 })
    }

    func testNoConflictWhenSystemShortcutDisabled() {
        let apple: [String: Any] = [
            "30": [
                "enabled": false,
                "value": [
                    "type": "standard",
                    "parameters": [52, 21, 1_179_648],
                ],
            ],
        ]
        let octo = OctoshotHotkeySet(
            area: .systemAreaCapture,
            window: .systemScreenshotOptions,
            fullscreen: .systemFullscreenCapture
        )
        let conflicts = SymbolicHotkeyPlist.conflicts(octoshot: octo, appleSymbolicHotKeys: apple)
        XCTAssertFalse(conflicts.contains { $0.id == 30 })
    }

    func testBackupCaptureAndRestoreByID() throws {
        let original: [String: Any] = [
            "AppleSymbolicHotKeys": [
                "28": [
                    "enabled": true,
                    "value": ["type": "standard", "parameters": [51, 20, 1_179_648]],
                ],
            ],
        ]
        var backup = SymbolicHotkeyIDBackup()
        let apple = original["AppleSymbolicHotKeys"] as! [String: Any]
        backup = SymbolicHotkeyPlistEditor.captureBackup(ids: [28, 30], appleSymbolicHotKeys: apple, into: backup)
        if case .entry(let saved28) = backup.states["28"] {
            XCTAssertEqual(saved28["enabled"] as? Bool, true)
        } else {
            XCTFail("expected backup for 28")
        }
        if case .missingFromPlist = backup.states["30"] {
        } else {
            XCTFail("expected missing backup for 30")
        }

        let disabled = SymbolicHotkeyPlistEditor.disableScreenshotHotkeys(ids: [28, 30], in: original)
        let disabledApple = disabled["AppleSymbolicHotKeys"] as! [String: Any]
        XCTAssertEqual((disabledApple["28"] as? [String: Any])?["enabled"] as? Bool, false)
        XCTAssertEqual((disabledApple["30"] as? [String: Any])?["enabled"] as? Bool, false)

        let restored = SymbolicHotkeyPlistEditor.restore(backup: backup, into: disabled)
        let restoredApple = restored["AppleSymbolicHotKeys"] as! [String: Any]
        XCTAssertNotNil(restoredApple["28"])
        XCTAssertNil(restoredApple["30"])
    }

    func testRecordingConflictRequiresModifier() {
        let octo = OctoshotHotkeySet(area: .areaDefault, window: .windowDefault, fullscreen: .fullscreenDefault)
        let conflict = SymbolicHotkeyPlist.recordingConflict(
            candidate: HotkeyBinding(keyCode: HotkeyKeyCode.ansi4, modifiers: 0),
            replacing: "area",
            octoshot: octo,
            systemEntries: []
        )
        XCTAssertEqual(conflict, "modifier_required")
    }

    func testRecordingConflictDetectsOctoshotDuplicate() {
        let octo = OctoshotHotkeySet(area: .systemAreaCapture, window: .windowDefault, fullscreen: .fullscreenDefault)
        let conflict = SymbolicHotkeyPlist.recordingConflict(
            candidate: .systemAreaCapture,
            replacing: "window",
            octoshot: octo,
            systemEntries: []
        )
        XCTAssertEqual(conflict, "octoshot_duplicate")
    }

    func testRecordingConflictDetectsSystemShortcut() {
        let octo = OctoshotHotkeySet(area: .systemAreaCapture, window: .windowDefault, fullscreen: .fullscreenDefault)
        let copyFullScreen = HotkeyBinding(
            keyCode: HotkeyKeyCode.ansi3,
            modifiers: HotkeyCarbonModifiers.command
                | HotkeyCarbonModifiers.shift
                | HotkeyCarbonModifiers.control
        )
        let system = [
            ResolvedSymbolicHotkey(id: 29, enabled: true, binding: copyFullScreen, usesStockDefaults: false),
        ]
        let conflict = SymbolicHotkeyPlist.recordingConflict(
            candidate: copyFullScreen,
            replacing: "area",
            octoshot: octo,
            systemEntries: system
        )
        XCTAssertEqual(conflict, "system_duplicate")
    }
}
