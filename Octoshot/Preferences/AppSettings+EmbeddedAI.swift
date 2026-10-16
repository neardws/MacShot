import Foundation
import OctoshotCore

extension AppSettings {
    var embeddedAIUseOnDeviceVLM: Bool {
        get {
            UserDefaults.standard.object(forKey: EmbeddedAISettings.userDefaultsKeys.useEmbeddedVision) as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: EmbeddedAISettings.userDefaultsKeys.useEmbeddedVision)
        }
    }

    var embeddedAIOllamaFallbackEnabled: Bool {
        get {
            UserDefaults.standard.object(forKey: EmbeddedAISettings.userDefaultsKeys.ollamaFallbackEnabled) as? Bool ?? false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: EmbeddedAISettings.userDefaultsKeys.ollamaFallbackEnabled)
        }
    }
}
