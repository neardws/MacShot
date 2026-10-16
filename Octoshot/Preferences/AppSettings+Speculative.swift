import Foundation

extension AppSettings {
    private enum SpeculativeKeys {
        static let enabled = "speculativePostProcessingEnabled"
        static let confidenceThreshold = "speculativeConfidenceThreshold"
    }

    var speculativePostProcessingEnabled: Bool {
        get { UserDefaults.standard.object(forKey: SpeculativeKeys.enabled) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: SpeculativeKeys.enabled) }
    }

    /// Minimum normalized confidence (0…1) to run background post-processing.
    var speculativeConfidenceThreshold: Double {
        get {
            let v = UserDefaults.standard.double(forKey: SpeculativeKeys.confidenceThreshold)
            return v > 0 ? v : 0.45
        }
        set { UserDefaults.standard.set(newValue, forKey: SpeculativeKeys.confidenceThreshold) }
    }
}
