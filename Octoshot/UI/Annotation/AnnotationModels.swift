import AppKit
import OctoshotCore

enum AnnotationTool: String, CaseIterable, Identifiable {
    case arrow
    case rectangle
    case text
    case pixelate
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
        case .rectangle: return "Rectangle"
        case .text: return "Text"
        case .pixelate: return "Pixelate"
        case .measure: return "Measure"
        }
    }

    var symbol: String {
        switch self {
        case .arrow: return "arrow.up.right"
        case .rectangle: return "rectangle"
        case .text: return "textformat"
        case .pixelate: return "checkerboard.rectangle"
        case .measure: return "ruler"
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
