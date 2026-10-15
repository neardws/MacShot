import AppKit

public struct CaptureSourceMetadata: Codable, Sendable {
    public var capturedAt: Date
    public var frontmostApp: String?
    public var bundleIdentifier: String?
    public var windowTitle: String?
    public var urlString: String?
    public var documentPath: String?
}

public enum CaptureSourceRecorder {
    public static func current() -> CaptureSourceMetadata {
        let workspace = NSWorkspace.shared
        let app = workspace.frontmostApplication
        var meta = CaptureSourceMetadata(
            capturedAt: Date(),
            frontmostApp: app?.localizedName,
            bundleIdentifier: app?.bundleIdentifier,
            windowTitle: nil,
            urlString: nil,
            documentPath: nil
        )
        if let title = activeWindowTitle() {
            meta.windowTitle = title
        }
        if let url = browserURL(from: app) {
            meta.urlString = url
        }
        if let path = documentPath(from: app) {
            meta.documentPath = path
        }
        return meta
    }

    private static func activeWindowTitle() -> String? {
        let system = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(system, kAXFocusedWindowAttribute as CFString, &focused)
        guard err == .success, let window = focused else { return nil }
        var titleValue: CFTypeRef?
        AXUIElementCopyAttributeValue(window as! AXUIElement, kAXTitleAttribute as CFString, &titleValue)
        return titleValue as? String
    }

    private static func browserURL(from app: NSRunningApplication?) -> String? {
        guard let bundle = app?.bundleIdentifier?.lowercased() else { return nil }
        let browsers = ["com.apple.safari", "com.google.chrome", "org.mozilla.firefox", "company.thebrowser.browser"]
        guard browsers.contains(where: { bundle.contains($0.split(separator: ".").last.map(String.init) ?? "") }) || bundle.contains("safari") || bundle.contains("chrome") else {
            return nil
        }
        return nil
    }

    private static func documentPath(from app: NSRunningApplication?) -> String? {
        app?.localizedName
    }
}
