import AppKit
import ScreenCaptureKit

public enum ShareableWindowFilter {
    public static func pickableWindows(from content: SCShareableContent) -> [SCWindow] {
        let ownBundle = Bundle.main.bundleIdentifier
        return content.windows
            .filter { window in
                guard window.isOnScreen else { return false }
                guard window.windowLayer == 0 else { return false }
                guard window.frame.width >= 60, window.frame.height >= 40 else { return false }
                if window.title?.isEmpty == true, window.owningApplication == nil { return false }
                if let bundle = window.owningApplication?.bundleIdentifier, bundle == ownBundle {
                    return false
                }
                return true
            }
            .sorted { $0.windowLayer > $1.windowLayer }
    }

    public static func window(at cocoaGlobalPoint: NSPoint, in windows: [SCWindow]) -> SCWindow? {
        let topLeft = DisplayGeometry.topLeftPoint(fromCocoaGlobal: cocoaGlobalPoint)
        return windows.first { $0.frame.contains(topLeft) }
    }

    public static func displayLabel(for window: SCWindow) -> String {
        if let title = window.title, !title.isEmpty {
            if let app = window.owningApplication?.applicationName, !app.isEmpty {
                return "\(app) — \(title)"
            }
            return title
        }
        return window.owningApplication?.applicationName ?? "Window"
    }
}
