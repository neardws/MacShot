import AppKit
import SwiftUI

@MainActor
final class PreferencesWindowController {
    private var window: NSWindow?

    func show(reregisterHotkeys: @escaping () -> Void) {
        if window == nil {
            let view = PreferencesView(onHotkeysChanged: reregisterHotkeys)
            let hosting = NSHostingController(rootView: view)
            let window = NSWindow(contentViewController: hosting)
            window.title = "MacShot Preferences"
            window.styleMask = [.titled, .closable]
            window.setContentSize(NSSize(width: 480, height: 360))
            window.center()
            self.window = window
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct PreferencesView: View {
    @ObservedObject private var settings = AppSettings.shared
    var onHotkeysChanged: () -> Void

    @State private var recordingTarget: HotkeyTarget?

    enum HotkeyTarget: String {
        case area, window, fullscreen
    }

    var body: some View {
        Form {
            Section("Save") {
                HStack {
                    Text(settings.saveDirectory.path)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
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
            }

            Section("Quick Access") {
                Picker("Corner", selection: $settings.quickAccessCorner) {
                    ForEach(QuickAccessCorner.allCases) { corner in
                        Text(corner.displayName).tag(corner)
                    }
                }
            }

            Section("Hotkeys") {
                hotkeyRow("Area", binding: $settings.hotkeyArea, target: .area)
                hotkeyRow("Window", binding: $settings.hotkeyWindow, target: .window)
                hotkeyRow("Fullscreen", binding: $settings.hotkeyFullscreen, target: .fullscreen)
                Text("Click Record, then press the desired key combination.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Permissions") {
                HStack {
                    Text(PermissionManager.hasScreenRecordingAccess ? "Screen Recording: granted" : "Screen Recording: not granted")
                    Spacer()
                    Button("Open Settings") { PermissionManager.openScreenRecordingSettings() }
                }
            }
        }
        .padding()
        .onChange(of: settings.hotkeyArea) { _, _ in onHotkeysChanged() }
        .onChange(of: settings.hotkeyWindow) { _, _ in onHotkeysChanged() }
        .onChange(of: settings.hotkeyFullscreen) { _, _ in onHotkeysChanged() }
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
                    let binding = HotkeyBinding(
                        keyCode: UInt32(event.keyCode),
                        modifiers: HotkeyFormatter.modifiersFromEvent(event)
                    )
                    switch target {
                    case .area: settings.hotkeyArea = binding
                    case .window: settings.hotkeyWindow = binding
                    case .fullscreen: settings.hotkeyFullscreen = binding
                    }
                    recordingTarget = nil
                }
            }
        }
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

@MainActor
final class HotkeyRecorder {
    static let shared = HotkeyRecorder()
    private var monitor: Any?

    func start(handler: @escaping (NSEvent) -> Void) {
        stop()
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            if event.modifierFlags.intersection([.command, .shift, .option, .control]).isEmpty {
                return event
            }
            handler(event)
            return nil
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}
