import AppKit
import Foundation
import OctoshotCore

#if canImport(MLXVLM) && canImport(MLXLMCommon)
import MLXVLM
import MLXLMCommon
#endif

/// Loads SmolVLM2 from `~/Library/Application Support/Octoshot/Models/`.
enum MLXVLMLoader {
    static let shared = Loader()

    final class Loader: @unchecked Sendable {
        #if canImport(MLXVLM) && canImport(MLXLMCommon)
        private var session: ChatSession?
        private var loadTask: Task<Void, Error>?
        #endif

        func respond(prompt: String, image: NSImage) async throws -> String {
            #if canImport(MLXVLM) && canImport(MLXLMCommon)
            try await ensureLoaded()
            guard let session else { throw EmbeddedAIError.backendMissing }
            let imageInput = try writeTempPNG(image)
            return try await session.respond(to: prompt, image: .url(imageInput))
            #else
            throw EmbeddedAIError.inferenceUnavailableInThisBuild
            #endif
        }

        #if canImport(MLXVLM) && canImport(MLXLMCommon)
        private func ensureLoaded() async throws {
            if session != nil { return }
            if let loadTask {
                try await loadTask.value
                return
            }
            let task = Task { @MainActor in
                let directory = EmbeddedAIModelPaths.directory(for: .smolVLM2_500M_4bit)
                let configuration = ModelConfiguration(directory: directory)
                let model = try await loadModel(configuration: configuration)
                self.session = ChatSession(model)
            }
            loadTask = task
            try await task.value
            loadTask = nil
        }

        private func writeTempPNG(_ image: NSImage) throws -> URL {
            guard let tiff = image.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff),
                  let png = rep.representation(using: .png, properties: [:]) else {
                throw EmbeddedAIError.backendMissing
            }
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("octoshot-vlm-\(UUID().uuidString).png")
            try png.write(to: url)
            return url
        }
        #endif
    }
}
