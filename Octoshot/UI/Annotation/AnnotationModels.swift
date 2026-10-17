import AppKit
import OctoshotCore

enum AnnotationTool: String, CaseIterable, Identifiable {
    case arrow
    case line
    case rectangle
    case ellipse
    case pen
    case highlighter
    case text
    case counter
    case pixelate
    case blur
    case crop
    case measure

    var id: String { rawValue }

    static var standardTools: [AnnotationTool] {
        allCases.filter { $0 != .measure }
    }

    static func visibleTools(developerMode: Bool) -> [AnnotationTool] {
        developerMode ? allCases : standardTools
    }

    var label: String {
        switch self {
        case .arrow: return "Arrow"
        case .line: return "Line"
        case .rectangle: return "Rectangle"
        case .ellipse: return "Ellipse"
        case .pen: return "Pen"
        case .highlighter: return "Highlighter"
        case .text: return "Text"
        case .counter: return "Counter"
        case .pixelate: return "Pixelate"
        case .blur: return "Blur"
        case .crop: return "Crop"
        case .measure: return "Measure"
        }
    }

    var symbol: String {
        switch self {
        case .arrow: return "arrow.up.right"
        case .line: return "line.diagonal"
        case .rectangle: return "rectangle"
        case .ellipse: return "circle"
        case .pen: return "pencil.tip"
        case .highlighter: return "highlighter"
        case .text: return "textformat"
        case .counter: return "number.circle"
        case .pixelate: return "checkerboard.rectangle"
        case .blur: return "drop.circle"
        case .crop: return "crop"
        case .measure: return "ruler"
        }
    }

    var usesDragRect: Bool {
        switch self {
        case .arrow, .line, .rectangle, .ellipse, .pixelate, .blur, .crop, .measure:
            return true
        default:
            return false
        }
    }

    var usesFreehand: Bool {
        self == .pen || self == .highlighter
    }
}

struct AnnotationStroke: Equatable {
    var tool: AnnotationTool
    var start: CGPoint
    var end: CGPoint
    var text: String
    var color: NSColor
    var lineWidth: CGFloat
    /// Image-space points for pen and highlighter.
    var points: [CGPoint] = []
    var counterValue: Int?
}

enum AnnotationStrokeStyle {
    static let presetWidths: [CGFloat] = [2, 4, 6, 10, 16]
    static let presetColors: [NSColor] = [
        .systemRed,
        .systemOrange,
        .systemYellow,
        .systemGreen,
        .systemBlue,
        .systemPurple,
        .white,
        .black
    ]
}
