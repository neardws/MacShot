import AppKit
import Foundation
import OctoshotCore

#if EMBEDDED_MLX
import MLXVLM
import MLXLMCommon
#endif

/// Loads SmolVLM2 from `~/Library/Application Support/Octoshot/Models/`.
@MainActor
public enum MLXVLMLoader {
    public static let shared = Loader()

    public final class Loader {
        #if EMBEDDED_MLX
        private var session: ChatSession?
        private var loadTask: Task<Void, Error>?
        #endif

        public func respond(prompt: String, image: NSImage) async throws -> String {
            #if EMBEDDED_MLX
            try await ensureLoaded()
            guard let session else { throw EmbeddedAIError.backendMissing }
            let imageURL = try writeTempPNG(image)
            return try await session.respond(to: prompt, image: .url(imageURL))
            #else
            throw EmbeddedAIError.inferenceUnavailableInThisBuild
            #endif
        }

        #if EMBEDDED_MLX
        private func ensureLoaded() async throws {
            if session != nil { return }
            if let loadTask {
                try await loadTask.value
                return
            }
            let task = Task { @MainActor in
                let directory = EmbeddedAIModelPaths.directory(for: .smolVLM2_500M_4bit)
                let configuration = ModelConfiguration(directory: directory)
                let container = try await VLMModelFactory.shared.loadContainer(configuration: configuration)
                self.session = ChatSession(container)
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
