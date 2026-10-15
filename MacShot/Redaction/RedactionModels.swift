import CoreGraphics
import Foundation

enum RedactionKind: String, Codable, CaseIterable, Identifiable {
    case phone
    case email
    case nationalID
    case creditCard
    case apiKey
    case ipAddress
    case face
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .phone: return "Phone"
        case .email: return "Email"
        case .nationalID: return "ID Number"
        case .creditCard: return "Card"
        case .apiKey: return "API Key"
        case .ipAddress: return "IP"
        case .face: return "Face"
        case .other: return "Sensitive"
        }
    }
}

struct RedactionCandidate: Identifiable, Equatable {
    let id: UUID
    var rect: CGRect
    var kind: RedactionKind
    var detail: String
    var isEnabled: Bool

    init(id: UUID = UUID(), rect: CGRect, kind: RedactionKind, detail: String, isEnabled: Bool = true) {
        self.id = id
        self.rect = rect
        self.kind = kind
        self.detail = detail
        self.isEnabled = isEnabled
    }
}
