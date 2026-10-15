import AppKit
import SwiftUI

struct MacShotSettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsPane()
                .tabItem { Label("General", systemImage: "gearshape") }
            ShortcutsSettingsPane()
                .tabItem { Label("Shortcuts", systemImage: "command") }
            OutputSettingsPane()
                .tabItem { Label("Output", systemImage: "folder") }
            QuickAccessSettingsPane()
                .tabItem { Label("Quick Access", systemImage: "photo.on.rectangle.angled") }
            PermissionsSettingsPane()
                .tabItem { Label("Permissions", systemImage: "lock.shield") }
            AboutSettingsPane()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(minWidth: 560, minHeight: 440)
        .padding(8)
    }
}

// MARK: - General

private struct GeneralSettingsPane: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        Form {
            Toggle("Launch MacShot at login", isOn: $settings.launchAtLogin)
            Toggle("Show menu bar icon", isOn: $settings.showMenuBarIcon)
            Toggle("Play sound after capture", isOn: $settings.playCaptureSound)

            Section {
                Text("After capture")
                    .font(.headline)
                Toggle("Show quick-access panel", isOn: $settings.afterCaptureShowQuickAccess)
                Toggle("Copy to clipboard", isOn: $settings.afterCaptureCopyToClipboard)
                Toggle("Save to disk", isOn: $settings.afterCaptureSaveToDisk)
            }

            Text("If quick access is off, you can still copy or save automatically using the options above.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Shortcuts

private struct ShortcutsSettingsPane: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var recordingTarget: HotkeyTarget?

    enum HotkeyTarget: String {
        case area, window, fullscreen
    }

    var body: some View {
        Form {
            hotkeyRow("Capture area", binding: $settings.hotkeyArea, target: .area)
            hotkeyRow("Capture window", binding: $settings.hotkeyWindow, target: .window)
            hotkeyRow("Capture fullscreen", binding: $settings.hotkeyFullscreen, target: .fullscreen)

            Text("Click Record, then press a shortcut that includes ⌘, ⌥, ⌃, or ⇧.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Reset to Defaults") {
                settings.resetHotkeysToDefaults()
            }
        }
        .formStyle(.grouped)
        .padding()
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
}

// MARK: - Output

private struct OutputSettingsPane: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        Form {
            Toggle("Include window shadow in window capture", isOn: $settings.captureWindowWithShadow)

            HStack {
                Text("Save folder")
                Spacer()
                Text(settings.saveDirectory.path)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(.secondary)
                Button("Choose…") { chooseSaveFolder() }
            }

            Picker("Format", selection: $settings.format) {
                ForEach(ScreenshotFormat.allCases) { format in
                    Text(format.displayName).tag(format)
                }
            }

            if settings.format == .jpeg {
                Slider(value: $settings.jpegQuality, in: 0.5...1.0) {
                    Text("JPEG quality")
                }
            }

            TextField("Filename pattern", text: $settings.filenamePattern)
            Text("Tokens: {prefix}, {date}, {time}, {datetime}. Extension is added automatically.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .padding()
    }

    private func chooseSaveFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = settings.saveDirectory
        if panel.runModal() == .OK, let url = panel.url {
            settings.saveDirectory = url
        }
    }
}

// MARK: - Quick Access

private struct QuickAccessSettingsPane: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        Form {
            Picker("Corner", selection: $settings.quickAccessCorner) {
                ForEach(QuickAccessCorner.allCases) { corner in
                    Text(corner.displayName).tag(corner)
                }
            }

            HStack {
                Text("Auto-close delay")
                Slider(value: $settings.quickAccessAutoCloseSeconds, in: 0...120, step: 5)
                Text(settings.quickAccessAutoCloseSeconds == 0 ? "Off" : "\(Int(settings.quickAccessAutoCloseSeconds))s")
                    .monospacedDigit()
                    .frame(width: 44, alignment: .trailing)
            }

            Text("When enabled, the quick-access thumbnail closes automatically after the delay.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Permissions

private struct PermissionsSettingsPane: View {
    @ObservedObject private var accessCache = ScreenRecordingAccessCache.shared
    @State private var isChecking = false
    @State private var statusMessage = "Checking Screen Recording access…"

    private var hasAccess: Bool {
        accessCache.lastKnownGranted ?? PermissionManager.legacyPreflightAccess
    }

    var body: some View {
        Form {
            HStack {
                Image(systemName: hasAccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(hasAccess ? .green : .orange)
                Text(statusMessage)
                Spacer()
                Button(isChecking ? "Checking…" : "Refresh") {
                    Task { await refreshStatus() }
                }
                .disabled(isChecking)
            }

            Button("Open System Settings") {
                PermissionManager.openScreenRecordingSettings()
            }

            Text("Status uses ScreenCaptureKit (live) because CGPreflightScreenCaptureAccess can be stale after you grant permission, especially with ad-hoc debug builds.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("System Settings → Privacy & Security → Screen Recording → enable MacShot, then quit and reopen.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .padding()
        .task { await refreshStatus() }
    }

    @MainActor
    private func refreshStatus() async {
        isChecking = true
        let granted = await PermissionManager.refreshAccessStatus()
        accessCache.lastKnownGranted = granted
        statusMessage = granted
            ? "Screen Recording is enabled for MacShot (verified via ScreenCaptureKit)."
            : "Screen Recording not detected — enable MacShot in System Settings."
        isChecking = false
    }
}

// MARK: - About

private struct AboutSettingsPane: View {
    private var appVersion: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApplication.shared.applicationIconImage ?? NSImage(size: NSSize(width: 64, height: 64)))
                .resizable()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            Text("MacShot")
                .font(.title2.bold())
            Text("Version \(appVersion)")
                .foregroundStyle(.secondary)
            Link("View on GitHub", destination: AppSettings.repositoryURL)
            Text("Released under the MIT License.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}
