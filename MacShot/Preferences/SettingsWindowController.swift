import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 580, height: 480),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "MacShot Settings"
        window.isReleasedWhenClosed = false
        window.center()

        let hosting = NSHostingController(rootView: MacShotSettingsView())
        window.contentViewController = hosting

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        guard let window else { return }

        if NSApp.activationPolicy() == .accessory {
            NSApp.setActivationPolicy(.regular)
        }
        NSApp.activate(ignoringOtherApps: true)

        if !window.isVisible {
            showWindow(nil)
        }
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }
}
