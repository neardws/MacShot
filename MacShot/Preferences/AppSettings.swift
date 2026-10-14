import AppKit
import Carbon.HIToolbox
import Foundation

enum ScreenshotFormat: String, CaseIterable, Identifiable {
    case png
    case jpeg

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .png: return "PNG"
        case .jpeg: return "JPEG"
        }
    }

    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        }
    }
}

enum QuickAccessCorner: String, CaseIterable, Identifiable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomRight: return "Bottom Right"
        }
    }
}

struct HotkeyBinding: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let areaDefault = HotkeyBinding(keyCode: 21, modifiers: UInt32(cmdKey | shiftKey)) // ⌘⇧5
    static let windowDefault = HotkeyBinding(keyCode: 23, modifiers: UInt32(cmdKey | shiftKey)) // ⌘⇧6
    static let fullscreenDefault = HotkeyBinding(keyCode: 22, modifiers: UInt32(cmdKey | shiftKey)) // ⌘⇧7
}

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private enum Keys {
        static let saveDirectory = "saveDirectory"
        static let format = "screenshotFormat"
        static let corner = "quickAccessCorner"
        static let hotkeyArea = "hotkeyArea"
        static let hotkeyWindow = "hotkeyWindow"
        static let hotkeyFullscreen = "hotkeyFullscreen"
        static let jpegQuality = "jpegQuality"
    }

    @Published var saveDirectory: URL {
        didSet {
            UserDefaults.standard.set(saveDirectory.path, forKey: Keys.saveDirectory)
        }
    }

    @Published var format: ScreenshotFormat {
        didSet {
            UserDefaults.standard.set(format.rawValue, forKey: Keys.format)
        }
    }

    @Published var quickAccessCorner: QuickAccessCorner {
        didSet {
            UserDefaults.standard.set(quickAccessCorner.rawValue, forKey: Keys.corner)
        }
    }

    @Published var jpegQuality: Double {
        didSet {
            UserDefaults.standard.set(jpegQuality, forKey: Keys.jpegQuality)
        }
    }

    @Published var hotkeyArea: HotkeyBinding {
        didSet { persistHotkey(hotkeyArea, key: Keys.hotkeyArea) }
    }

    @Published var hotkeyWindow: HotkeyBinding {
        didSet { persistHotkey(hotkeyWindow, key: Keys.hotkeyWindow) }
    }

    @Published var hotkeyFullscreen: HotkeyBinding {
        didSet { persistHotkey(hotkeyFullscreen, key: Keys.hotkeyFullscreen) }
    }

    private init() {
        let desktop = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop", isDirectory: true)
        if let path = UserDefaults.standard.string(forKey: Keys.saveDirectory) {
            saveDirectory = URL(fileURLWithPath: path, isDirectory: true)
        } else {
            saveDirectory = desktop
        }

        if let raw = UserDefaults.standard.string(forKey: Keys.format),
           let value = ScreenshotFormat(rawValue: raw) {
            format = value
        } else {
            format = .png
        }

        if let raw = UserDefaults.standard.string(forKey: Keys.corner),
           let value = QuickAccessCorner(rawValue: raw) {
            quickAccessCorner = value
        } else {
            quickAccessCorner = .bottomRight
        }

        let quality = UserDefaults.standard.double(forKey: Keys.jpegQuality)
        jpegQuality = quality > 0 ? quality : 0.85

        hotkeyArea = Self.loadHotkey(key: Keys.hotkeyArea) ?? .areaDefault
        hotkeyWindow = Self.loadHotkey(key: Keys.hotkeyWindow) ?? .windowDefault
        hotkeyFullscreen = Self.loadHotkey(key: Keys.hotkeyFullscreen) ?? .fullscreenDefault
    }

    private func persistHotkey(_ binding: HotkeyBinding, key: String) {
        if let data = try? JSONEncoder().encode(binding) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private static func loadHotkey(key: String) -> HotkeyBinding? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(HotkeyBinding.self, from: data)
    }

    func defaultSaveURL(prefix: String = "Screenshot") -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        let stamp = formatter.string(from: Date())
        let filename = "\(prefix) \(stamp).\(format.fileExtension)"
        return saveDirectory.appendingPathComponent(filename)
    }
}
