import AppKit
import Carbon.HIToolbox
import Foundation

enum ScreenshotFormat: String, CaseIterable, Identifiable, Codable {
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

enum QuickAccessCorner: String, CaseIterable, Identifiable, Codable {
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

extension Notification.Name {
    static let macShotHotkeysDidChange = Notification.Name("MacShotHotkeysDidChange")
    static let macShotMenuBarVisibilityDidChange = Notification.Name("MacShotMenuBarVisibilityDidChange")
}

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    static let defaultFilenamePattern = "{prefix} {date} {time}"
    static let repositoryURL = URL(string: "https://github.com/neardws/MacShot")!

    private enum Keys {
        static let saveDirectory = "saveDirectory"
        static let format = "screenshotFormat"
        static let corner = "quickAccessCorner"
        static let hotkeyArea = "hotkeyArea"
        static let hotkeyWindow = "hotkeyWindow"
        static let hotkeyFullscreen = "hotkeyFullscreen"
        static let jpegQuality = "jpegQuality"
        static let launchAtLogin = "launchAtLogin"
        static let showMenuBarIcon = "showMenuBarIcon"
        static let playCaptureSound = "playCaptureSound"
        static let afterCaptureQuickAccess = "afterCaptureQuickAccess"
        static let afterCaptureCopy = "afterCaptureCopy"
        static let afterCaptureSave = "afterCaptureSave"
        static let filenamePattern = "filenamePattern"
        static let quickAccessAutoClose = "quickAccessAutoCloseSeconds"
    }

    @Published var saveDirectory: URL {
        didSet { UserDefaults.standard.set(saveDirectory.path, forKey: Keys.saveDirectory) }
    }

    @Published var format: ScreenshotFormat {
        didSet { UserDefaults.standard.set(format.rawValue, forKey: Keys.format) }
    }

    @Published var quickAccessCorner: QuickAccessCorner {
        didSet { UserDefaults.standard.set(quickAccessCorner.rawValue, forKey: Keys.corner) }
    }

    @Published var jpegQuality: Double {
        didSet { UserDefaults.standard.set(jpegQuality, forKey: Keys.jpegQuality) }
    }

    @Published var hotkeyArea: HotkeyBinding {
        didSet {
            persistHotkey(hotkeyArea, key: Keys.hotkeyArea)
            NotificationCenter.default.post(name: .macShotHotkeysDidChange, object: nil)
        }
    }

    @Published var hotkeyWindow: HotkeyBinding {
        didSet {
            persistHotkey(hotkeyWindow, key: Keys.hotkeyWindow)
            NotificationCenter.default.post(name: .macShotHotkeysDidChange, object: nil)
        }
    }

    @Published var hotkeyFullscreen: HotkeyBinding {
        didSet {
            persistHotkey(hotkeyFullscreen, key: Keys.hotkeyFullscreen)
            NotificationCenter.default.post(name: .macShotHotkeysDidChange, object: nil)
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin)
            LaunchAtLoginManager.setEnabled(launchAtLogin)
        }
    }

    @Published var showMenuBarIcon: Bool {
        didSet {
            UserDefaults.standard.set(showMenuBarIcon, forKey: Keys.showMenuBarIcon)
            NotificationCenter.default.post(name: .macShotMenuBarVisibilityDidChange, object: nil)
        }
    }

    @Published var playCaptureSound: Bool {
        didSet { UserDefaults.standard.set(playCaptureSound, forKey: Keys.playCaptureSound) }
    }

    @Published var afterCaptureShowQuickAccess: Bool {
        didSet { UserDefaults.standard.set(afterCaptureShowQuickAccess, forKey: Keys.afterCaptureQuickAccess) }
    }

    @Published var afterCaptureCopyToClipboard: Bool {
        didSet { UserDefaults.standard.set(afterCaptureCopyToClipboard, forKey: Keys.afterCaptureCopy) }
    }

    @Published var afterCaptureSaveToDisk: Bool {
        didSet { UserDefaults.standard.set(afterCaptureSaveToDisk, forKey: Keys.afterCaptureSave) }
    }

    @Published var filenamePattern: String {
        didSet { UserDefaults.standard.set(filenamePattern, forKey: Keys.filenamePattern) }
    }

    /// Seconds before the quick-access panel auto-closes. `0` disables auto-close.
    @Published var quickAccessAutoCloseSeconds: Double {
        didSet { UserDefaults.standard.set(quickAccessAutoCloseSeconds, forKey: Keys.quickAccessAutoClose) }
    }

    private init() {
        let desktop = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop", isDirectory: true)
        if let path = UserDefaults.standard.string(forKey: Keys.saveDirectory) {
            saveDirectory = URL(fileURLWithPath: path, isDirectory: true)
        } else {
            saveDirectory = desktop
        }

        format = ScreenshotFormat(rawValue: UserDefaults.standard.string(forKey: Keys.format) ?? "") ?? .png
        quickAccessCorner = QuickAccessCorner(rawValue: UserDefaults.standard.string(forKey: Keys.corner) ?? "") ?? .bottomRight

        let quality = UserDefaults.standard.double(forKey: Keys.jpegQuality)
        jpegQuality = quality > 0 ? quality : 0.85

        hotkeyArea = Self.loadHotkey(key: Keys.hotkeyArea) ?? .areaDefault
        hotkeyWindow = Self.loadHotkey(key: Keys.hotkeyWindow) ?? .windowDefault
        hotkeyFullscreen = Self.loadHotkey(key: Keys.hotkeyFullscreen) ?? .fullscreenDefault

        if UserDefaults.standard.object(forKey: Keys.launchAtLogin) != nil {
            launchAtLogin = UserDefaults.standard.bool(forKey: Keys.launchAtLogin)
        } else {
            launchAtLogin = LaunchAtLoginManager.isEnabled
        }

        if UserDefaults.standard.object(forKey: Keys.showMenuBarIcon) != nil {
            showMenuBarIcon = UserDefaults.standard.bool(forKey: Keys.showMenuBarIcon)
        } else {
            showMenuBarIcon = true
        }

        playCaptureSound = UserDefaults.standard.object(forKey: Keys.playCaptureSound) as? Bool ?? true
        afterCaptureShowQuickAccess = UserDefaults.standard.object(forKey: Keys.afterCaptureQuickAccess) as? Bool ?? true
        afterCaptureCopyToClipboard = UserDefaults.standard.bool(forKey: Keys.afterCaptureCopy)
        afterCaptureSaveToDisk = UserDefaults.standard.bool(forKey: Keys.afterCaptureSave)

        filenamePattern = UserDefaults.standard.string(forKey: Keys.filenamePattern) ?? Self.defaultFilenamePattern
        quickAccessAutoCloseSeconds = UserDefaults.standard.object(forKey: Keys.quickAccessAutoClose) as? Double ?? 0
    }

    func resetHotkeysToDefaults() {
        hotkeyArea = .areaDefault
        hotkeyWindow = .windowDefault
        hotkeyFullscreen = .fullscreenDefault
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
        let filename = resolvedFilename(prefix: prefix)
        return saveDirectory.appendingPathComponent(filename)
    }

    func resolvedFilename(prefix: String) -> String {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH.mm.ss"

        var name = filenamePattern
        name = name.replacingOccurrences(of: "{prefix}", with: prefix)
        name = name.replacingOccurrences(of: "{date}", with: dateFormatter.string(from: now))
        name = name.replacingOccurrences(of: "{time}", with: timeFormatter.string(from: now))
        name = name.replacingOccurrences(
            of: "{datetime}",
            with: "\(dateFormatter.string(from: now)) \(timeFormatter.string(from: now))"
        )
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            name = "\(prefix) \(dateFormatter.string(from: now)) \(timeFormatter.string(from: now))"
        }
        if !name.lowercased().hasSuffix(".\(format.fileExtension)") {
            name += ".\(format.fileExtension)"
        }
        return name
    }
}
