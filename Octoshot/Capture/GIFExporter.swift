import AppKit
import ImageIO
import OctoshotCore
import UniformTypeIdentifiers

enum GIFExporter {
    static func writeGIF(frames: [NSImage], fps: Double, maxWidth: Int, to url: URL) throws {
        guard !frames.isEmpty else { return }
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, frames.count, nil) else {
            throw CaptureError.captureFailed("Could not create GIF destination")
        }
        let frameDelay = 1.0 / max(fps, 1)
        let properties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: 0
            ]
        ]
        CGImageDestinationSetProperties(destination, properties as CFDictionary)

        for frame in frames {
            let scaled = scale(frame, maxWidth: maxWidth)
            guard let cg = scaled.cgImage(forProposedRect: nil, context: nil, hints: nil) else { continue }
            let frameProps: [String: Any] = [
                kCGImagePropertyGIFDictionary as String: [
                    kCGImagePropertyGIFDelayTime as String: frameDelay
                ]
            ]
            CGImageDestinationAddImage(destination, cg, frameProps as CFDictionary)
        }
        if !CGImageDestinationFinalize(destination) {
            throw CaptureError.captureFailed("GIF finalize failed")
        }
    }

    static func scale(_ image: NSImage, maxWidth: Int) -> NSImage {
        let w = image.size.width
        let h = image.size.height
        guard w > CGFloat(maxWidth) else { return image }
        let scale = CGFloat(maxWidth) / w
        let newSize = NSSize(width: CGFloat(maxWidth), height: h * scale)
        let out = NSImage(size: newSize)
        out.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize))
        out.unlockFocus()
        return out
    }
}
