import Foundation

extension AppSettings {
    private enum RecordingKeys {
        static let rememberAreaCaptureMode = "rememberAreaCaptureMode"
        static let lastAreaCaptureMode = "lastAreaCaptureMode"
        static let gifFPS = "gifFPS"
        static let gifMaxWidth = "gifMaxWidth"
        static let recordSystemAudio = "recordSystemAudio"
        static let recordMicrophone = "recordMicrophone"
        static let recordShowClicks = "recordShowClicks"
        static let recordShowCursor = "recordShowCursor"
        static let scrollAutoScroll = "scrollAutoScroll"
        static let recordStopHotkeyEnabled = "recordStopHotkeyEnabled"
    }

    var rememberAreaCaptureMode: Bool {
        get { UserDefaults.standard.object(forKey: RecordingKeys.rememberAreaCaptureMode) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: RecordingKeys.rememberAreaCaptureMode) }
    }

    var lastAreaCaptureMode: AreaCaptureMode {
        get {
            let raw = UserDefaults.standard.string(forKey: RecordingKeys.lastAreaCaptureMode) ?? AreaCaptureMode.screenshot.rawValue
            return AreaCaptureMode(rawValue: raw) ?? .screenshot
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: RecordingKeys.lastAreaCaptureMode) }
    }

    var gifFPS: Double {
        get {
            let v = UserDefaults.standard.double(forKey: RecordingKeys.gifFPS)
            return v > 0 ? v : 10
        }
        set { UserDefaults.standard.set(newValue, forKey: RecordingKeys.gifFPS) }
    }

    var gifMaxWidth: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: RecordingKeys.gifMaxWidth)
            return v > 0 ? v : 800
        }
        set { UserDefaults.standard.set(newValue, forKey: RecordingKeys.gifMaxWidth) }
    }

    var recordSystemAudio: Bool {
        get { UserDefaults.standard.object(forKey: RecordingKeys.recordSystemAudio) as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: RecordingKeys.recordSystemAudio) }
    }

    var recordMicrophone: Bool {
        get { UserDefaults.standard.object(forKey: RecordingKeys.recordMicrophone) as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: RecordingKeys.recordMicrophone) }
    }

    var recordShowClicks: Bool {
        get { UserDefaults.standard.object(forKey: RecordingKeys.recordShowClicks) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: RecordingKeys.recordShowClicks) }
    }

    var recordShowCursor: Bool {
        get { UserDefaults.standard.object(forKey: RecordingKeys.recordShowCursor) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: RecordingKeys.recordShowCursor) }
    }

    var scrollCaptureAutoScroll: Bool {
        get { UserDefaults.standard.object(forKey: RecordingKeys.scrollAutoScroll) as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: RecordingKeys.scrollAutoScroll) }
    }
}
