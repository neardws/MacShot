import AppKit
import OctoshotCore

@MainActor
final class Pix2TexService: EmbeddedLaTeXBackend, @unchecked Sendable {
    static let shared = Pix2TexService()

    private init() {}

    func isReady() -> Bool {
        EmbeddedAIModelPaths.isInstalled(.pix2texMFR_Q4)
    }

    func toLaTeX(image: NSImage) async throws -> String {
        guard EmbeddedAIModelPaths.isInstalled(.pix2texMFR_Q4) else {
            throw EmbeddedAIError.modelNotInstalled(.pix2texMFR_Q4)
        }
        let modelPath = EmbeddedAIModelPaths.directory(for: .pix2texMFR_Q4)
            .appendingPathComponent(EmbeddedModelID.pix2texMFR_Q4.primaryGGUFFileName ?? "pix2tex-mfr-Q4_K.gguf")
        let raw = try await Pix2TexLlamaRunner.run(image: image, modelPath: modelPath)
        return cleanLaTeXOutput(raw)
    }

    private func cleanLaTeXOutput(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "```latex", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
