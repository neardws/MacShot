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
                On-device MLX inference is not linked in this build. Add the mlx-swift-lm package (MLXVLM) in Xcode, or enable Ollama fallback in Settings → AI.
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
