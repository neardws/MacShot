import Foundation
import OctoshotCore

enum EmbeddedAIFriendlyErrors {
    static func message(for error: Error, model: String) -> String {
        if let embedded = error as? EmbeddedAIError {
            switch embedded {
            case .modelNotInstalled(let id):
                return "\(embedded.localizedDescription) Tap Download in Settings → AI."
            case .inferenceUnavailableInThisBuild:
                return """
                On-device MLX inference is disabled in this build (EMBEDDED_MLX=0). Use a release build with EMBEDDED_MLX=1, or enable Ollama fallback in Settings → AI.
                """
            case .specialistFailed(let detail):
                return detail
            default:
                return embedded.localizedDescription
            }
        }
        return OllamaService.friendlyAIError(error, model: model)
    }
}
