import Foundation

enum AreaCaptureFollowUp: Equatable {
    case standard
    case latex
    case paperClip
}

@MainActor
final class CaptureFollowUpState {
    static let shared = CaptureFollowUpState()
    var areaFollowUp: AreaCaptureFollowUp = .standard
}
