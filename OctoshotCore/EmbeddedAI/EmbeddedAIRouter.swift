import AppKit
import Foundation

public struct EmbeddedAISettings: Sendable {
    public var useEmbeddedVision: Bool
    public var ollamaFallbackEnabled: Bool
    public var ollamaReachable: Bool

    public init(useEmbeddedVision: Bool, ollamaFallbackEnabled: Bool, ollamaReachable: Bool) {
        self.useEmbeddedVision = useEmbeddedVision
        self.ollamaFallbackEnabled = ollamaFallbackEnabled
        self.ollamaReachable = ollamaReachable
    }

    public static let userDefaultsKeys = (
        useEmbeddedVision: "embeddedAIUseOnDeviceVLM",
        ollamaFallbackEnabled: "embeddedAIOllamaFallbackEnabled"
    )
}

@MainActor
public enum EmbeddedAIRouter {
    public static func askAI(image: NSImage, prompt: String, settings: EmbeddedAISettings) async throws -> String {
        if settings.useEmbeddedVision, EmbeddedAIModelPaths.isInstalled(.smolVLM2_500M_4bit) {
            if let backend = EmbeddedAIProvider.vision, backend.isReady() {
                return try await backend.complete(prompt: prompt, image: image)
            }
        }
        if settings.ollamaFallbackEnabled, settings.ollamaReachable {
            return try await AgentConfiguration.openAIClient().completeVisionChat(prompt: prompt, image: image)
        }
        if !EmbeddedAIModelPaths.isInstalled(.smolVLM2_500M_4bit) {
            throw EmbeddedAIError.modelNotInstalled(.smolVLM2_500M_4bit)
        }
        throw EmbeddedAIError.backendMissing
    }

    public static func streamAskAI(
        image: NSImage,
        prompt: String,
        settings: EmbeddedAISettings
    ) -> AsyncThrowingStream<String, Error> {
        if settings.useEmbeddedVision,
           EmbeddedAIModelPaths.isInstalled(.smolVLM2_500M_4bit),
           let backend = EmbeddedAIProvider.vision,
           backend.isReady() {
            return backend.stream(prompt: prompt, image: image)
        }
        if settings.ollamaFallbackEnabled, settings.ollamaReachable {
            let client = AgentConfiguration.openAIClient()
            return client.streamVisionChat(prompt: prompt, image: image)
        }
        return AsyncThrowingStream { continuation in
            if !EmbeddedAIModelPaths.isInstalled(.smolVLM2_500M_4bit) {
                continuation.finish(throwing: EmbeddedAIError.modelNotInstalled(.smolVLM2_500M_4bit))
            } else {
                continuation.finish(throwing: EmbeddedAIError.backendMissing)
            }
        }
    }

    public static func toLaTeX(
        image: NSImage,
        vlmPrompt: String,
        settings: EmbeddedAISettings
    ) async throws -> String {
        if EmbeddedAIModelPaths.isInstalled(.pix2texMFR_Q4),
           let latexBackend = EmbeddedAIProvider.latex,
           latexBackend.isReady() {
            do {
                let specialist = try await latexBackend.toLaTeX(image: image)
                let trimmed = specialist.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return trimmed }
            } catch {
                // Fall through to VLM / Ollama
            }
        }

        if settings.useEmbeddedVision, EmbeddedAIModelPaths.isInstalled(.smolVLM2_500M_4bit),
           let backend = EmbeddedAIProvider.vision, backend.isReady() {
            return try await backend.complete(prompt: vlmPrompt, image: image)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if settings.ollamaFallbackEnabled, settings.ollamaReachable {
            return try await AgentConfiguration.openAIClient().completeVisionChat(prompt: vlmPrompt, image: image)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if !EmbeddedAIModelPaths.isInstalled(.pix2texMFR_Q4) && !EmbeddedAIModelPaths.isInstalled(.smolVLM2_500M_4bit) {
            throw EmbeddedAIError.modelNotInstalled(.pix2texMFR_Q4)
        }
        throw EmbeddedAIError.backendMissing
    }

    public static func extractTable(image: NSImage, settings: EmbeddedAISettings) async throws -> String {
        try await askAI(image: image, prompt: AIPrompts.tableExtract, settings: settings)
    }
}
