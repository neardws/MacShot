import AppKit
import Foundation
import OctoshotCore

@MainActor
enum AgentURLRouter {
    /// Handles `octoshot://capture?...` and `octoshot://record?action=start|stop&mode=...&format=video|gif&rect=`
    static func handle(_ url: URL) {
        guard url.scheme?.lowercased() == "octoshot" else { return }
        let host = url.host?.lowercased() ?? ""
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        switch host {
        case "capture":
            handleCapture(query: query)
        case "record":
            handleRecord(query: query)
        default:
            break
        }
    }

    private static func handleCapture(query: [URLQueryItem]) {
        func value(_ name: String) -> String? {
            query.first { $0.name == name }?.value
        }

        let mode = value("mode") ?? "fullscreen"
        Task {
            do {
                switch mode {
                case "area", "region":
                    CaptureCoordinator.shared.startAreaCapture()
                case "window":
                    CaptureCoordinator.shared.startWindowCapture()
                case "fullscreen", "display":
                    _ = try await AgentCaptureEngine.capture(options: .init(
                        mode: mode == "display" ? .display : .fullscreen,
                        displayID: value("display_id").flatMap { UInt32($0) },
                        outputPath: value("output").map { URL(fileURLWithPath: $0) }
                    ))
                default:
                    CaptureCoordinator.shared.startFullscreenCapture()
                }
            } catch {
                NSAlert(error: error).runModal()
            }
        }
    }

    private static func handleRecord(query: [URLQueryItem]) {
        func value(_ name: String) -> String? {
            query.first { $0.name == name }?.value
        }

        let action = value("action") ?? "start"
        switch action.lowercased() {
        case "stop":
            CaptureCoordinator.shared.stopRecording()
        case "start":
            let format = value("format") ?? "video"
            let kind: RecordingKind = format.lowercased() == "gif" ? .gif : .video
            if let rect = parseRect(value("rect")) {
                ScreenCaptureRecorder.shared.startRegion(rect, kind: kind)
                return
            }
            let mode = value("mode") ?? "fullscreen"
            switch mode.lowercased() {
            case "area", "region":
                CaptureCoordinator.shared.startAreaCapture()
            default:
                CaptureCoordinator.shared.startFullscreenRecording(video: kind == .video)
            }
        default:
            break
        }
    }

    private static func parseRect(_ raw: String?) -> CGRect? {
        guard let raw else { return nil }
        let parts = raw.split(separator: ",").compactMap { Double($0) }
        guard parts.count == 4 else { return nil }
        return CGRect(x: parts[0], y: parts[1], width: parts[2], height: parts[3])
    }
}
