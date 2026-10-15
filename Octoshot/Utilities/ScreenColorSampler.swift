import AppKit
import OctoshotCore

struct ScreenColorInfo: Equatable {
    let red: Int
    let green: Int
    let blue: Int
    let alpha: Int

    var hexRGB: String {
        String(format: "#%02X%02X%02X", red, green, blue)
    }

    var rgbText: String {
        "rgb(\(red), \(green), \(blue))"
    }

    var pasteboardText: String { hexRGB }
}

enum ScreenColorSampler {
    /// Samples the on-screen pixel at an AppKit global point (bottom-left origin).
    static func sample(at cocoaGlobal: NSPoint) -> ScreenColorInfo? {
        guard NSScreen.screens.contains(where: { $0.frame.contains(cocoaGlobal) }) else { return nil }
        let screen = NSScreen.screens.first { $0.frame.contains(cocoaGlobal) } ?? NSScreen.main
        let scale = screen?.backingScaleFactor ?? 2
        let side = max(1.0 / scale, 0.5)
        let rect = CGRect(
            x: cocoaGlobal.x - side / 2,
            y: cocoaGlobal.y - side / 2,
            width: side,
            height: side
        )
        guard let cgImage = CGWindowListCreateImage(
            rect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        ) else { return nil }

        let rep = NSBitmapImageRep(cgImage: cgImage)
        let x = max(0, rep.pixelsWide / 2)
        let y = max(0, rep.pixelsHigh / 2)
        guard let color = rep.colorAt(x: x, y: y) else { return nil }
        guard let rgb = color.usingColorSpace(.deviceRGB) else { return nil }
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        rgb.getRed(&r, green: &g, blue: &b, alpha: &a)
        return ScreenColorInfo(
            red: Int(round(r * 255)),
            green: Int(round(g * 255)),
            blue: Int(round(b * 255)),
            alpha: Int(round(a * 255))
        )
    }
}
