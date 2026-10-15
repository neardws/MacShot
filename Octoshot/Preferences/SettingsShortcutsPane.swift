import AppKit
import SwiftUI
import OctoshotCore

struct SettingsShortcutsPane: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var recordingTarget: HotkeyTarget?
    @State private var systemEntries: [SystemScreenshotHotkeys.Entry] = []
    @State private var plistMessage: String?

    enum HotkeyTarget: String {
        case area, window, fullscreen
    }

    var body: some View {
        SettingsFormContainer {
            SettingsPaneHeader(
                title: "Shortcuts",
                subtitle: "Global capture hotkeys and macOS screenshot bindings",
                systemImage: "command"
            )

            Section {
                hotkeyRow("Capture fullscreen", binding: $settings.hotkeyFullscreen, target: .fullscreen)
                hotkeyRow("Capture area", binding: $settings.hotkeyArea, target: .area)
                hotkeyRow("Capture window", binding: $settings.hotkeyWindow, target: .window)
                Text("Click Record, then press a shortcut that includes ⌘, ⌥, ⌃, or ⇧.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Reset to Defaults") { settings.resetHotkeysToDefaults() }
            } header: {
                Label("Octoshot hotkeys", systemImage: "keyboard")
            }

            Section {
                ForEach(systemEntries) { entry in
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title)
                            if let binding = entry.binding {
                                Text(HotkeyFormatter.displayString(for: binding))
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(entry.enabled ? "Enabled" : "Disabled")
                            .foregroundStyle(entry.enabled ? .primary : .secondary)
                    }
                }
                Button("Refresh system bindings") { reloadSystem() }
            } header: {
                Label("macOS screenshot shortcuts", systemImage: "apple.logo")
            }

            Section {
                let conflicts = SystemScreenshotHotkeys.conflicts(with: settings)
                if !conflicts.isEmpty {
                    Label(
                        "System shortcuts still enabled for the same keys — captures may open both apps.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(.orange)
                    .font(.caption)
                }

                Button("Use Octoshot for ⌘⇧3 / ⌘⇧4 / ⌘⇧5") {
                    SystemScreenshotHotkeys.applyOctoshotTakeover()
                    SystemScreenshotHotkeys.openKeyboardSettings()
                }

                Text("This sets Octoshot to the standard screenshot keys. Disable the matching items under System Settings → Keyboard → Keyboard Shortcuts → Screenshots.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Open Keyboard Shortcuts…") {
                    SystemScreenshotHotkeys.openKeyboardSettings()
                }

                Button("Disable system screenshot hotkeys (advanced)…") {
                    confirmDisableSystemHotkeys()
                }

                if SystemScreenshotHotkeys.hasBackup {
                    Button("Restore system screenshot hotkeys") {
                        restoreSystemHotkeys()
                    }
                }

                if let plistMessage {
                    Text(plistMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label("Take over system shortcuts", systemImage: "arrow.triangle.swap")
            }
        }
        .onAppear { reloadSystem() }
    }

    private func reloadSystem() {
        systemEntries = SystemScreenshotHotkeys.loadEntries()
    }

    private func hotkeyRow(_ title: String, binding: Binding<HotkeyBinding>, target: HotkeyTarget) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(HotkeyFormatter.displayString(for: binding.wrappedValue))
                .font(.system(.body, design: .monospaced))
            Button(recordingTarget == target ? "Press keys…" : "Record") {
                recordingTarget = target
                HotkeyRecorder.shared.start { event in
                    let newBinding = HotkeyBinding(
                        keyCode: UInt32(event.keyCode),
                        modifiers: HotkeyFormatter.modifiersFromEvent(event)
                    )
                    switch target {
                    case .area: settings.hotkeyArea = newBinding
                    case .window: settings.hotkeyWindow = newBinding
                    case .fullscreen: settings.hotkeyFullscreen = newBinding
                    }
                    recordingTarget = nil
                    HotkeyRecorder.shared.stop()
                }
            }
        }
    }

    private func confirmDisableSystemHotkeys() {
        let alert = NSAlert()
        alert.messageText = "Disable macOS screenshot shortcuts?"
        alert.informativeText = """
        Octoshot will back up your symbolic hotkeys plist and turn off screenshot shortcuts (IDs 28, 29, 30, 31, 184).

        You may need to log out and back in for macOS to reload shortcuts. Use Restore if anything looks wrong.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Disable")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        do {
            try SystemScreenshotHotkeys.disableSystemScreenshotHotkeys()
            plistMessage = "System screenshot shortcuts disabled. A backup was saved in Application Support/Octoshot."
            reloadSystem()
        } catch {
            plistMessage = error.localizedDescription
        }
    }

    private func restoreSystemHotkeys() {
        do {
            try SystemScreenshotHotkeys.restoreSystemScreenshotHotkeys()
            plistMessage = "Restored system screenshot shortcuts from backup."
            reloadSystem()
        } catch {
            plistMessage = error.localizedDescription
        }
    }
}
