import SwiftUI
import OctoshotCore

@main
struct OctoshotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Settings UI is hosted by `SettingsWindowController` (LSUIElement-safe).
        // Keep an empty Settings scene so SwiftUI provides a standard app lifecycle.
        Settings {
            EmptyView()
        }
    }
}
