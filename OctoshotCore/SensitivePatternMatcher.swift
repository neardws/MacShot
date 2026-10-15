import Foundation

public enum SensitivePatternMatcher {
    struct Match {
        let kind: RedactionKind
        let range: Range<String.Index>
        let value: String
    }

    static func matches(in text: String, settings: RedactionSettingsSnapshot) -> [Match] {
        var results: [Match] = []
        if settings.redactEmails {
            results += find(pattern: #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#, options: [.caseInsensitive], in: text, kind: .email)
        }
        if settings.redactPhones {
            results += find(pattern: #"(?:\+?86[-\s]?)?1[3-9]\d{9}"#, in: text, kind: .phone)
            results += find(pattern: #"(?:\+?\d{1,3}[-\s]?)?(?:\(?\d{2,4}\)?[-\s]?)?\d{3,4}[-\s]?\d{4}"#, in: text, kind: .phone)
        }
        if settings.redactNationalIDs {
            results += find(pattern: #"\b\d{17}[\dXx]\b"#, in: text, kind: .nationalID)
        }
        if settings.redactCreditCards {
            results += find(pattern: #"\b(?:\d[ -]*?){13,19}\b"#, in: text, kind: .creditCard)
        }
        if settings.redactAPIKeys {
            results += find(pattern: #"\b(sk-[A-Za-z0-9]{10,}|ghp_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,})\b"#, in: text, kind: .apiKey)
            results += find(pattern: #"\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9._-]+\b"#, in: text, kind: .apiKey)
        }
        if settings.redactIPAddresses {
            results += find(pattern: #"\b(?:(?:25[0-5]|2[0-4]\d|[01]?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d?\d)\b"#, in: text, kind: .ipAddress)
        }
        return results
    }

    private static func find(
        pattern: String,
        options: NSRegularExpression.Options = [],
        in text: String,
        kind: RedactionKind
    ) -> [Match] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return [] }
        let ns = text as NSString
        let full = NSRange(location: 0, length: ns.length)
        return regex.matches(in: text, options: [], range: full).compactMap { result in
            guard let range = Range(result.range, in: text) else { return nil }
            let value = String(text[range])
            if kind == .creditCard, digitsOnly(value).count < 13 { return nil }
            return Match(kind: kind, range: range, value: value)
        }
    }

    private static func digitsOnly(_ value: String) -> String {
        value.filter(\.isNumber)
    }
}

public struct RedactionSettingsSnapshot: Sendable {
    public var redactPhones: Bool
    public var redactEmails: Bool
    public var redactNationalIDs: Bool
    public var redactCreditCards: Bool
    public var redactAPIKeys: Bool
    public var redactIPAddresses: Bool
    public var redactFaces: Bool

    public init(
        redactPhones: Bool,
        redactEmails: Bool,
        redactNationalIDs: Bool,
        redactCreditCards: Bool,
        redactAPIKeys: Bool,
        redactIPAddresses: Bool,
        redactFaces: Bool
    ) {
        self.redactPhones = redactPhones
        self.redactEmails = redactEmails
        self.redactNationalIDs = redactNationalIDs
        self.redactCreditCards = redactCreditCards
        self.redactAPIKeys = redactAPIKeys
        self.redactIPAddresses = redactIPAddresses
        self.redactFaces = redactFaces
    }
}

