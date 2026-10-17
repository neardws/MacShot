import AppKit

/// Shared window configuration so capture overlays and quick-access UI appear on the
/// same full-screen Space as the frontmost app without activating Octoshot away from it.
public enum FullScreenOverlaySupport {
    public static let overlayLevel = NSWindow.Level.screenSaver

    public static var overlayCollectionBehavior: NSWindow.CollectionBehavior {
        [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
    }

    public static func configureCaptureOverlayPanel(_ panel: NSPanel) {
        panel.level = overlayLevel
        panel.collectionBehavior = overlayCollectionBehavior
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
    }

    public static func configureFloatingOverlayPanel(_ panel: NSPanel) {
        configureCaptureOverlayPanel(panel)
    }

    /// Present overlay windows on top of full-screen apps without `NSApp.activate`, which would leave the Space.
    public static func presentCaptureOverlays(_ windows: [NSWindow]) {
        for window in windows {
            window.orderFrontRegardless()
        }
        focusOverlay(at: NSEvent.mouseLocation, in: windows)
    }

    public static func overlayWindow(at globalPoint: NSPoint, in windows: [NSWindow]) -> NSWindow? {
        windows.first(where: { $0.frame.contains(globalPoint) }) ?? windows.first
    }

    public static func focusOverlay(at globalPoint: NSPoint, in windows: [NSWindow]) {
        guard let target = overlayWindow(at: globalPoint, in: windows) else { return }
        target.orderFrontRegardless()
        target.makeKey()
    }
}
