import AppKit

enum AnnotationTool: String, CaseIterable, Identifiable {
    case arrow
    case rectangle
    case text
    case pixelate

    var id: String { rawValue }

    var label: String {
        switch self {
        case .arrow: return "Arrow"
        case .rectangle: return "Rectangle"
        case .text: return "Text"
        case .pixelate: return "Pixelate"
        }
    }

    var symbol: String {
        switch self {
        case .arrow: return "arrow.up.right"
        case .rectangle: return "rectangle"
        case .text: return "textformat"
        case .pixelate: return "checkerboard.rectangle"
        }
    }
}

struct AnnotationStroke: Equatable {
    var tool: AnnotationTool
    var start: CGPoint
    var end: CGPoint
    var text: String
    var color: NSColor
    var lineWidth: CGFloat
}
