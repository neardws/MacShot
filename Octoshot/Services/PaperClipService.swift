import AppKit
import OctoshotCore

enum PaperClipService {
    @MainActor
    static func processFigure(image: NSImage) async throws -> URL {
        try await AgentProcessing.extractTableAndSaveClip(image: image)
    }
}
