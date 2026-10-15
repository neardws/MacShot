import AppKit
import UniformTypeIdentifiers

enum ImageFormats {
    static func pngData(from image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    static func jpegData(from image: NSImage, quality: Double) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(
            using: .jpeg,
            properties: [.compressionFactor: quality]
        )
    }

    static func data(for image: NSImage, format: ScreenshotFormat, jpegQuality: Double) -> Data? {
        switch format {
        case .png: return pngData(from: image)
        case .jpeg: return jpegData(from: image, quality: jpegQuality)
        }
    }

    static func write(image: NSImage, to url: URL, format: ScreenshotFormat, jpegQuality: Double) throws {
        guard let data = data(for: image, format: format, jpegQuality: jpegQuality) else {
            throw NSError(domain: "Octoshot", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"])
        }
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url)
    }

    static func copyToPasteboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
}
