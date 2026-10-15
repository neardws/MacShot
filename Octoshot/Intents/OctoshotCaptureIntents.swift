import AppIntents
import OctoshotCore

struct CaptureFullscreenIntent: AppIntent {
    static var title: LocalizedStringResource = "Capture Fullscreen (Octoshot)"
    static var description = IntentDescription("Capture the current display using Octoshot.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        _ = try await AgentCaptureEngine.capture(options: .init(mode: .fullscreen))
        return .result()
    }
}

struct CaptureWindowIntent: AppIntent {
    static var title: LocalizedStringResource = "Capture Window (Octoshot)"
    static var description = IntentDescription("Capture a specific window by ID (from list-windows).")

    @Parameter(title: "Window ID")
    var windowID: Int

    func perform() async throws -> some IntentResult {
        _ = try await AgentCaptureEngine.capture(options: .init(mode: .window, windowID: UInt32(windowID)))
        return .result()
    }
}

struct OctoshotShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CaptureFullscreenIntent(),
            phrases: [
                "Capture fullscreen with \(.applicationName)",
                "Take a fullscreen screenshot with \(.applicationName)"
            ],
            shortTitle: "Fullscreen capture",
            systemImageName: "camera.viewfinder"
        )
    }
}
