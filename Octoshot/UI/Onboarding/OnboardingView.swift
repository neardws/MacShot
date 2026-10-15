import AppKit
import SwiftUI
import OctoshotCore

enum OnboardingStore {
    private static let key = "didCompleteOnboarding"

    static var isComplete: Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    static func markComplete() {
        UserDefaults.standard.set(true, forKey: key)
    }
}

struct OnboardingView: View {
    @ObservedObject private var accessCache = ScreenRecordingAccessCache.shared
    @State private var step = 0
    @State private var isCheckingPermission = false
    @State private var vlmInstalled = EmbeddedAIModelPaths.isInstalled(.smolVLM2_500M_4bit)
    @State private var downloadNote = ""
    @State private var isDownloading = false
    @Environment(\.dismiss) private var dismiss

    private var hasScreenRecording: Bool {
        accessCache.lastKnownGranted ?? PermissionManager.legacyPreflightAccess
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $step) {
                welcomeStep.tag(0)
                permissionStep.tag(1)
                shortcutsStep.tag(2)
                aiStep.tag(3)
            }
            .tabViewStyle(.automatic)

            HStack {
                if step > 0 {
                    Button("Back") { step -= 1 }
                }
                Spacer()
                if step < 3 {
                    Button("Continue") { step += 1 }
                        .keyboardShortcut(.defaultAction)
                } else {
                    Button("Get started") {
                        OnboardingStore.markComplete()
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding()
        }
        .frame(width: 520, height: 420)
        .task { await refreshPermission() }
    }

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 72, height: 72)
            Text("Welcome to Octoshot")
                .font(.title.bold())
            Text("Local-first screenshots with annotation, redaction, and on-device AI (SmolVLM2 + pix2tex).")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }

    private var permissionStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Screen Recording")
                .font(.title2.bold())
            Label(
                hasScreenRecording ? "Permission looks good." : "Octoshot needs Screen Recording to capture your display.",
                systemImage: hasScreenRecording ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
            )
            .foregroundStyle(hasScreenRecording ? .green : .orange)
            Button("Open System Settings") {
                PermissionManager.openScreenRecordingSettings()
            }
            Button(isCheckingPermission ? "Checking…" : "Refresh status") {
                Task { await refreshPermission() }
            }
            .disabled(isCheckingPermission)
            Text("After enabling, quit and reopen Octoshot if captures still fail.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var shortcutsStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shortcuts")
                .font(.title2.bold())
            Text("Use Octoshot with the familiar ⌘⇧3 / ⌘⇧4 / ⌘⇧5 keys, then disable the built-in macOS screenshot shortcuts.")
                .foregroundStyle(.secondary)
            Button("Use Octoshot for ⌘⇧3/4/5") {
                SystemScreenshotHotkeys.applyOctoshotTakeover()
                SystemScreenshotHotkeys.openKeyboardSettings()
            }
            Button("Open Settings → Shortcuts") {
                NotificationCenter.default.post(name: .octoshotOpenSettingsSection, object: SettingsSection.shortcuts)
                SettingsOpener.open()
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var aiStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("On-device AI")
                .font(.title2.bold())
            Text("Download SmolVLM2 (~292 MB) for Ask AI and tables. Add pix2tex (~18 MB) for fast LaTeX. Models stay in Application Support — not in the app bundle.")
                .foregroundStyle(.secondary)
            if vlmInstalled {
                Label("SmolVLM2 is installed.", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button(isDownloading ? "Downloading…" : "Download SmolVLM2") {
                    Task { await downloadSmolVLM() }
                }
                .disabled(isDownloading)
            }
            if !downloadNote.isEmpty {
                Text(downloadNote).font(.caption).foregroundStyle(.secondary)
            }
            Button("Open Settings → AI") {
                NotificationCenter.default.post(name: .octoshotOpenSettingsSection, object: SettingsSection.ai)
                SettingsOpener.open()
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @MainActor
    private func downloadSmolVLM() async {
        isDownloading = true
        downloadNote = "Downloading…"
        defer { isDownloading = false }
        do {
            try await ModelDownloadService.shared.download(.smolVLM2_500M_4bit)
            vlmInstalled = true
            downloadNote = "Download complete."
        } catch {
            downloadNote = error.localizedDescription
        }
    }

    @MainActor
    private func refreshPermission() async {
        isCheckingPermission = true
        let granted = await PermissionManager.refreshAccessStatus()
        accessCache.lastKnownGranted = granted
        isCheckingPermission = false
    }
}

@MainActor
enum OnboardingPresenter {
    private static var onboardingWindow: NSWindow?

    static func presentIfNeeded() {
        guard !OnboardingStore.isComplete else { return }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to Octoshot"
        window.center()
        window.contentViewController = NSHostingController(rootView: OnboardingView())
        window.isReleasedWhenClosed = false
        onboardingWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
