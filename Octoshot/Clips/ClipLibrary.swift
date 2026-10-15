import AppKit
import Foundation

struct ClipRecord: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let source: CaptureSourceMetadata
    let imageFilename: String
    var tableMarkdown: String?
    var tableCSV: String?
    var notes: String?
}

enum ClipLibrary {
    @MainActor
    static var rootDirectory: URL {
        AppSettings.shared.clipsLibraryDirectory
    }

    @MainActor
    static func save(
        image: NSImage,
        source: CaptureSourceMetadata,
        tableMarkdown: String? = nil,
        tableCSV: String? = nil,
        notes: String? = nil
    ) throws -> URL {
        let id = UUID()
        let folder = rootDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let imageURL = folder.appendingPathComponent("capture.png")
        try ImageFormats.write(image: image, to: imageURL, format: .png, jpegQuality: 0.9)

        if let tableMarkdown {
            try tableMarkdown.write(to: folder.appendingPathComponent("table.md"), atomically: true, encoding: .utf8)
        }
        if let tableCSV {
            try tableCSV.write(to: folder.appendingPathComponent("table.csv"), atomically: true, encoding: .utf8)
        }

        let record = ClipRecord(
            id: id,
            createdAt: Date(),
            source: source,
            imageFilename: "capture.png",
            tableMarkdown: tableMarkdown,
            tableCSV: tableCSV,
            notes: notes
        )
        let data = try JSONEncoder().encode(record)
        try data.write(to: folder.appendingPathComponent("metadata.json"))
        return folder
    }
}
