import AppKit
import Foundation

public struct ClipRecord: Codable, Identifiable, Sendable {
    public let id: UUID
    public let createdAt: Date
    public let source: CaptureSourceMetadata
    public let imageFilename: String
    public var tableMarkdown: String?
    public var tableCSV: String?
    public var notes: String?
}

public enum ClipLibrary {
    public static var rootDirectory: URL {
        AgentConfiguration.clipsLibraryDirectory
    }

    public static func save(
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
        try ImageFormats.writePNG(image: image, to: imageURL)

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
