import AppKit

enum DisplayGeometry {
    /// Height of the virtual desktop in AppKit global coordinates (bottom-left origin).
    static var virtualDesktopHeight: CGFloat {
        NSScreen.screens.map(\.frame.maxY).max() ?? NSScreen.main?.frame.maxY ?? 0
    }

    /// ScreenCaptureKit window frames use a top-left origin; AppKit uses bottom-left.
    static func cocoaRect(fromTopLeftFrame frame: CGRect) -> CGRect {
        let height = virtualDesktopHeight
        return CGRect(
            x: frame.origin.x,
            y: height - frame.origin.y - frame.height,
            width: frame.width,
            height: frame.height
        )
    }

    /// Converts a rect in AppKit global coordinates (bottom-left origin) to a rect
    /// relative to the given screen's frame, still in bottom-left origin.
    static func rectInScreenSpace(globalRect: CGRect, screen: NSScreen) -> CGRect {
        let frame = screen.frame
        return CGRect(
            x: globalRect.origin.x - frame.origin.x,
            y: globalRect.origin.y - frame.origin.y,
            width: globalRect.width,
            height: globalRect.height
        )
    }

    /// ScreenCaptureKit `sourceRect` uses top-left origin within the display.
    static func sourceRectForCapture(screenLocalBottomLeft: CGRect, displayHeight: CGFloat) -> CGRect {
        CGRect(
            x: screenLocalBottomLeft.origin.x,
            y: displayHeight - screenLocalBottomLeft.origin.y - screenLocalBottomLeft.height,
            width: screenLocalBottomLeft.width,
            height: screenLocalBottomLeft.height
        )
    }

    static func normalizedSelection(from start: NSPoint, to end: NSPoint) -> CGRect {
        let x = min(start.x, end.x)
        let y = min(start.y, end.y)
        let w = abs(end.x - start.x)
        let h = abs(end.y - start.y)
        return CGRect(x: x, y: y, width: w, height: h)
    }
}
