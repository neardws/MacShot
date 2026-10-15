import AppKit
import CoreGraphics
import ScreenCaptureKit

enum PermissionManager {
    private static let didPromptKey = "didShowScreenRecordingPrompt"

    /// `CGPreflightScreenCaptureAccess()` — fast but can stay `false` after TCC grants (ad-hoc signing, relaunch).
    static var legacyPreflightAccess: Bool {
        CGPreflightScreenCaptureAccess()
    }

    static var hasPromptedForScreenRecording: Bool {
        UserDefaults.standard.bool(forKey: didPromptKey)
    }

    private static func markPrompted() {
        UserDefaults.standard.set(true, forKey: didPromptKey)
    }

    /// Authoritative check: ScreenCaptureKit can enumerate shareable content.
    static func probeScreenCaptureKit() async -> Bool {
        do {
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            return true
        } catch {
            return false
        }
    }

    @MainActor
    static func refreshAccessStatus() async -> Bool {
        let granted = await probeScreenCaptureKit()
        if granted || legacyPreflightAccess {
            return true
        }
        return false
    }

    /// UI/status helper — prefers last async result when available.
    @MainActor
    static var displayHasScreenRecordingAccess: Bool {
        ScreenRecordingAccessCache.shared.lastKnownGranted
            ?? legacyPreflightAccess
    }

    @MainActor
    static func presentInitialGuidanceIfNeeded() async {
        if await refreshAccessStatus() {
            ScreenRecordingAccessCache.shared.lastKnownGranted = true
            return
        }
        guard !hasPromptedForScreenRecording else { return }
        await requestAccessGuidanceOnce()
    }

    /// Soft check before capture — never blocks capture; prompts at most once.
    @MainActor
    static func prepareForCaptureIfNeeded() async {
        if await probeScreenCaptureKit() {
            ScreenRecordingAccessCache.shared.lastKnownGranted = true
            return
        }
        guard !hasPromptedForScreenRecording else { return }
        await requestAccessGuidanceOnce()
    }

    @MainActor
    static func handleCaptureFailure(_ error: Error) async {
        if await probeScreenCaptureKit() {
            ScreenRecordingAccessCache.shared.lastKnownGranted = true
            return
        }
        guard isLikelyPermissionError(error) else { return }
        guard !hasPromptedForScreenRecording else { return }
        await requestAccessGuidanceOnce()
    }

    @MainActor
    private static func requestAccessGuidanceOnce() async {
        markPrompted()
        _ = CGRequestScreenCaptureAccess()
        if await probeScreenCaptureKit() {
            ScreenRecordingAccessCache.shared.lastKnownGranted = true
            return
        }
        showPermissionAlert()
    }

    private static func isLikelyPermissionError(_ error: Error) -> Bool {
        let ns = error as NSError
        if ns.domain.contains("ScreenCaptureKit") || ns.domain.contains("ScreenCapture") {
            return true
        }
        let message = ns.localizedDescription.lowercased()
        return message.contains("permission") || message.contains("declined") || message.contains("not authorized")
    }

    @MainActor
    static func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = """
        MacShot needs Screen Recording permission to capture your screen.

        Open System Settings → Privacy & Security → Screen Recording, enable MacShot, then quit and reopen the app.

        For development builds, use a stable code-signing identity (Apple Development team) so macOS remembers the grant across rebuilds.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openScreenRecordingSettings()
        }
    }

    static func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    @MainActor
    static func installActivationRefresh() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                let granted = await refreshAccessStatus()
                ScreenRecordingAccessCache.shared.lastKnownGranted = granted
            }
        }
    }
}

@MainActor
final class ScreenRecordingAccessCache: ObservableObject {
    static let shared = ScreenRecordingAccessCache()
    @Published var lastKnownGranted: Bool?

    private init() {}
}
