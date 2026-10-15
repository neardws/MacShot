import Foundation

public enum ScreenshotFormat: String, CaseIterable, Identifiable, Codable, Sendable {
    case png
    case jpeg

    public var id: String { rawValue }

    public var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        }
    }
}
