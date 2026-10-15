import Foundation

public extension EmbeddedAISettings {
    static func fromUserDefaults(ollamaReachable: Bool) -> EmbeddedAISettings {
        let defaults = UserDefaults.standard
        let useEmbedded = defaults.object(forKey: userDefaultsKeys.useEmbeddedVision) as? Bool ?? true
        let fallback = defaults.object(forKey: userDefaultsKeys.ollamaFallbackEnabled) as? Bool ?? false
        return EmbeddedAISettings(
            useEmbeddedVision: useEmbedded,
            ollamaFallbackEnabled: fallback,
            ollamaReachable: ollamaReachable
        )
    }

    static func markEmbeddedVLMInstalled() {
        UserDefaults.standard.set(false, forKey: userDefaultsKeys.ollamaFallbackEnabled)
    }
}
