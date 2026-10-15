import AppKit
import Foundation

public protocol EmbeddedVisionBackend: AnyObject, Sendable {
    @MainActor func isReady() -> Bool
    @MainActor func complete(prompt: String, image: NSImage) async throws -> String
    @MainActor func stream(prompt: String, image: NSImage) -> AsyncThrowingStream<String, Error>
}

public protocol EmbeddedLaTeXBackend: AnyObject, Sendable {
    @MainActor func isReady() -> Bool
    @MainActor func toLaTeX(image: NSImage) async throws -> String
}

public enum EmbeddedAIProvider {
    @MainActor public static weak var vision: (any EmbeddedVisionBackend)?
    @MainActor public static weak var latex: (any EmbeddedLaTeXBackend)?
}

public enum EmbeddedAIError: LocalizedError {
    case modelNotInstalled(EmbeddedModelID)
    case inferenceUnavailableInThisBuild
    case downloadFailed(String)
    case backendMissing
    case specialistFailed(String)

    public var errorDescription: String? {
        switch self {
        case .modelNotInstalled(let id):
            return "\(id.displayName) is not installed. Download it in Settings → AI."
        case .inferenceUnavailableInThisBuild:
            return "On-device inference is not available in this build. Install models in Settings → AI or enable Ollama fallback."
        case .downloadFailed(let detail):
            return "Model download failed: \(detail)"
        case .backendMissing:
            return "Embedded AI backend is not registered."
        case .specialistFailed(let detail):
            return "LaTeX specialist failed: \(detail)"
        }
    }
}

/// No-op backends used by CLI / tests.
public final class UnavailableEmbeddedVisionBackend: EmbeddedVisionBackend, @unchecked Sendable {
    public init() {}
    public func isReady() -> Bool { false }
    public func complete(prompt: String, image: NSImage) async throws -> String {
        throw EmbeddedAIError.backendMissing
    }
    public func stream(prompt: String, image: NSImage) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { $0.finish(throwing: EmbeddedAIError.backendMissing) }
    }
}

public final class UnavailableEmbeddedLaTeXBackend: EmbeddedLaTeXBackend, @unchecked Sendable {
    public init() {}
    public func isReady() -> Bool { false }
    public func toLaTeX(image: NSImage) async throws -> String {
        throw EmbeddedAIError.backendMissing
    }
}
