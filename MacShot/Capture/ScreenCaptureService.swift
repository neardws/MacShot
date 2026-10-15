import AppKit
import ScreenCaptureKit

enum CaptureError: LocalizedError {
    case noDisplays
    case noWindows
    case captureFailed(String)
    case emptySelection

    var errorDescription: String? {
        switch self {
        case .noDisplays: return "No displays available for capture."
        case .noWindows: return "No on-screen windows found."
        case .captureFailed(let reason): return "Capture failed: \(reason)"
        case .emptySelection: return "Selection area is too small."
        }
    }
}

final class ScreenCaptureService {
    static let shared = ScreenCaptureService()

    private init() {}

    func shareableContent() async throws -> SCShareableContent {
        try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
    }

    func captureFullscreen(display: SCDisplay? = nil) async throws -> NSImage {
        let content = try await shareableContent()
        guard let targetDisplay = display ?? content.displays.first else {
            throw CaptureError.noDisplays
        }
        let screen = screenForDisplayID(targetDisplay.displayID)
        let scale = screen?.backingScaleFactor ?? 2.0
        let filter = SCContentFilter(display: targetDisplay, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.width = Int(CGFloat(targetDisplay.width) * scale)
        config.height = Int(CGFloat(targetDisplay.height) * scale)
        config.showsCursor = true
        config.captureResolution = .best
        let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        return NSImage(cgImage: cgImage, size: NSSize(width: targetDisplay.width, height: targetDisplay.height))
    }

    func captureWindow(_ window: SCWindow) async throws -> NSImage {
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let scale = backingScaleFactor(forWindow: window)
        let config = SCStreamConfiguration()
        config.width = Int(window.frame.width * scale)
        config.height = Int(window.frame.height * scale)
        config.showsCursor = true
        // Window shadow is included in the SCWindow frame when enabled in settings; SCK captures the window content filter bounds.
        _ = UserDefaults.standard.object(forKey: "captureWindowWithShadow") as? Bool ?? true
        config.captureResolution = .best
        let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        return NSImage(cgImage: cgImage, size: NSSize(width: window.frame.width, height: window.frame.height))
    }

    func captureRegion(globalRect: CGRect) async throws -> NSImage {
        guard globalRect.width >= 2, globalRect.height >= 2 else {
            throw CaptureError.emptySelection
        }
        let content = try await shareableContent()
        let screens = NSScreen.screens
        var pieces: [(CGRect, NSImage)] = []

        for screen in screens {
            let intersection = globalRect.intersection(screen.frame)
            if intersection.isNull || intersection.width < 1 || intersection.height < 1 { continue }
            guard let display = content.displays.first(where: { $0.displayID == screen.displayID }) else { continue }
            let local = DisplayGeometry.rectInScreenSpace(globalRect: intersection, screen: screen)
            let source = DisplayGeometry.sourceRectForCapture(
                screenLocalBottomLeft: local,
                displayHeight: screen.frame.height
            )
            let scale = screen.backingScaleFactor
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()
            config.sourceRect = source
            config.width = Int(intersection.width * scale)
            config.height = Int(intersection.height * scale)
            config.showsCursor = true
            config.captureResolution = .best
            let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
            let piece = NSImage(cgImage: cgImage, size: intersection.size)
            let offsetInSelection = CGRect(
                x: intersection.origin.x - globalRect.origin.x,
                y: intersection.origin.y - globalRect.origin.y,
                width: intersection.width,
                height: intersection.height
            )
            pieces.append((offsetInSelection, piece))
        }

        guard !pieces.isEmpty else { throw CaptureError.noDisplays }
        return composite(pieces: pieces, canvasSize: globalRect.size)
    }

    private func composite(pieces: [(CGRect, NSImage)], canvasSize: CGSize) -> NSImage {
        let image = NSImage(size: canvasSize)
        image.lockFocus()
        for (rect, piece) in pieces {
            let drawRect = CGRect(
                x: rect.origin.x,
                y: rect.origin.y,
                width: rect.width,
                height: rect.height
            )
            piece.draw(in: drawRect)
        }
        image.unlockFocus()
        return image
    }

    private func screenForDisplayID(_ displayID: CGDirectDisplayID) -> NSScreen? {
        NSScreen.screens.first { $0.displayID == displayID }
    }

    private func backingScaleFactor(forWindow window: SCWindow) -> CGFloat {
        let center = CGPoint(x: window.frame.midX, y: window.frame.midY)
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(center) }) {
            return screen.backingScaleFactor
        }
        return NSScreen.main?.backingScaleFactor ?? 2.0
    }
}

private extension NSScreen {
    var displayID: CGDirectDisplayID {
        guard let number = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return 0
        }
        return CGDirectDisplayID(number.uint32Value)
    }
}
