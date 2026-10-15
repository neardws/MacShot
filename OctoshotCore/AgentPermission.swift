import Foundation
import ScreenCaptureKit

public enum AgentPermissionError: LocalizedError {
    case screenRecordingDenied

    public var errorDescription: String? {
        switch self {
        case .screenRecordingDenied:
            return "Screen Recording permission is required. Enable Octoshot in System Settings → Privacy & Security → Screen Recording."
        }
    }
}

public enum AgentPermission {
    public static func probeScreenCapture() async -> Bool {
        do {
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            return true
        } catch {
            return false
        }
    }

    public static func requireScreenCapture() async throws {
        guard await probeScreenCapture() else {
            throw AgentPermissionError.screenRecordingDenied
        }
    }
}
