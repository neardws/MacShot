import Foundation

extension AppSettings {
    private enum SignatureKeys {
        static let aiBaseURL = "aiBaseURL"
        static let aiVisionModel = "aiVisionModel"
        static let aiAPIKey = "aiAPIKey"
        static let aiLatexPrompt = "aiLatexPrompt"
        static let clipsLibraryDirectory = "clipsLibraryDirectory"
        static let autoRedactOnAnnotate = "autoRedactOnAnnotate"
        static let redactPhones = "redactPhones"
        static let redactEmails = "redactEmails"
        static let redactNationalIDs = "redactNationalIDs"
        static let redactCreditCards = "redactCreditCards"
        static let redactAPIKeys = "redactAPIKeys"
        static let redactIPAddresses = "redactIPAddresses"
        static let redactFaces = "redactFaces"
    }

    var aiBaseURL: URL {
        get {
            if let raw = UserDefaults.standard.string(forKey: SignatureKeys.aiBaseURL),
               let url = URL(string: raw) { return url }
            return URL(string: "http://localhost:11434/v1")!
        }
        set { UserDefaults.standard.set(newValue.absoluteString, forKey: SignatureKeys.aiBaseURL) }
    }

    var aiVisionModel: String {
        get { UserDefaults.standard.string(forKey: SignatureKeys.aiVisionModel) ?? "qwen2.5vl:latest" }
        set { UserDefaults.standard.set(newValue, forKey: SignatureKeys.aiVisionModel) }
    }

    var aiAPIKey: String {
        get { UserDefaults.standard.string(forKey: SignatureKeys.aiAPIKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: SignatureKeys.aiAPIKey) }
    }

    var aiLatexPrompt: String {
        get { UserDefaults.standard.string(forKey: SignatureKeys.aiLatexPrompt) ?? AIPrompts.latex }
        set { UserDefaults.standard.set(newValue, forKey: SignatureKeys.aiLatexPrompt) }
    }

    var clipsLibraryDirectory: URL {
        get {
            if let path = UserDefaults.standard.string(forKey: SignatureKeys.clipsLibraryDirectory) {
                return URL(fileURLWithPath: path, isDirectory: true)
            }
            let pictures = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Pictures/Octoshot Clips", isDirectory: true)
            return pictures
        }
        set { UserDefaults.standard.set(newValue.path, forKey: SignatureKeys.clipsLibraryDirectory) }
    }

    var autoRedactOnAnnotate: Bool {
        get { UserDefaults.standard.object(forKey: SignatureKeys.autoRedactOnAnnotate) as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: SignatureKeys.autoRedactOnAnnotate) }
    }

    var redactPhones: Bool {
        get { UserDefaults.standard.object(forKey: SignatureKeys.redactPhones) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: SignatureKeys.redactPhones) }
    }

    var redactEmails: Bool {
        get { UserDefaults.standard.object(forKey: SignatureKeys.redactEmails) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: SignatureKeys.redactEmails) }
    }

    var redactNationalIDs: Bool {
        get { UserDefaults.standard.object(forKey: SignatureKeys.redactNationalIDs) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: SignatureKeys.redactNationalIDs) }
    }

    var redactCreditCards: Bool {
        get { UserDefaults.standard.object(forKey: SignatureKeys.redactCreditCards) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: SignatureKeys.redactCreditCards) }
    }

    var redactAPIKeys: Bool {
        get { UserDefaults.standard.object(forKey: SignatureKeys.redactAPIKeys) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: SignatureKeys.redactAPIKeys) }
    }

    var redactIPAddresses: Bool {
        get { UserDefaults.standard.object(forKey: SignatureKeys.redactIPAddresses) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: SignatureKeys.redactIPAddresses) }
    }

    var redactFaces: Bool {
        get { UserDefaults.standard.object(forKey: SignatureKeys.redactFaces) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: SignatureKeys.redactFaces) }
    }
}
