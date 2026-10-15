import Foundation

enum SettingsSection: String, CaseIterable, Identifiable, Hashable {
    case general
    case shortcuts
    case capture
    case recording
    case annotation
    case ai
    case developer
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .shortcuts: return "Shortcuts"
        case .capture: return "Capture"
        case .recording: return "Recording"
        case .annotation: return "Annotation"
        case .ai: return "AI"
        case .developer: return "Developer"
        case .about: return "About"
        }
    }

    var systemImage: String {
        switch self {
        case .general: return "gearshape"
        case .shortcuts: return "command"
        case .capture: return "camera.viewfinder"
        case .recording: return "record.circle"
        case .annotation: return "pencil.and.outline"
        case .ai: return "brain"
        case .developer: return "hammer"
        case .about: return "info.circle"
        }
    }

    var subtitle: String {
        switch self {
        case .general: return "Startup, menu bar, and after capture"
        case .shortcuts: return "Global hotkeys and macOS screenshots"
        case .capture: return "Save folder, format, and quick access"
        case .recording: return "Video, GIF, scroll capture, and mode bar"
        case .annotation: return "Redaction and annotate defaults"
        case .ai: return "Ollama, LaTeX, and Clips library"
        case .developer: return "Dev tools and Agent CLI"
        case .about: return "Version and license"
        }
    }
}
