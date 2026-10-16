import Foundation

enum AreaCaptureMode: String, CaseIterable, Codable, Identifiable {
    case screenshot
    case scrolling
    case recordVideo
    case recordGIF
    case formulaLaTeX
    case figureTable

    var id: String { rawValue }

    var title: String {
        switch self {
        case .screenshot: return "Screenshot"
        case .scrolling: return "Scroll"
        case .recordVideo: return "Video"
        case .recordGIF: return "GIF"
        case .formulaLaTeX: return "LaTeX"
        case .figureTable: return "Figure"
        }
    }

    var modeBarLabel: String {
        switch self {
        case .screenshot: return "S"
        case .scrolling: return "R"
        case .recordVideo: return "V"
        case .recordGIF: return "G"
        case .formulaLaTeX: return "L"
        case .figureTable: return "T"
        }
    }

    /// Mode bar keys: S screenshot, R scroll, V video, G GIF, L LaTeX, T table/figure.
    static func modeForModeBarKey(_ character: String) -> AreaCaptureMode? {
        switch character.lowercased() {
        case "s": return .screenshot
        case "r": return .scrolling
        case "v": return .recordVideo
        case "g": return .recordGIF
        case "l": return .formulaLaTeX
        case "t": return .figureTable
        default: return nil
        }
    }
}
