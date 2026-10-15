import AppKit
import Foundation
import OctoshotCore

@MainActor
enum AgentURLRouter {
    /// Handles `octoshot://capture?mode=fullscreen|window|display|region&window_id=&display_id=&rect=`
    static func handle(_ url: URL) {
        guard url.scheme?.lowercased() == "octoshot" else { return }
        let host = url.host?.lowercased() ?? ""
        guard host == "capture" else { return }

        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
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
}
