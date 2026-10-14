import AppKit
import CoreGraphics

enum PermissionManager {
    static var hasScreenRecordingAccess: Bool {
        CGPreflightScreenCaptureAccess()
    }

    @MainActor
    static func ensureScreenRecordingAccess(promptIfNeeded: Bool) -> Bool {
        if CGPreflightScreenCaptureAccess() {
            return true
        }
        if promptIfNeeded {
            let granted = CGRequestScreenCaptureAccess()
            if granted { return true }
            showPermissionAlert()
        }
        return false
    }

    @MainActor
    static func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = """
        MacShot needs Screen Recording permission to capture your screen.

        Open System Settings → Privacy & Security → Screen Recording, enable MacShot, then try again.
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
}
