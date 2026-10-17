import AppKit
import SwiftUI

@MainActor
final class HelpWindowController: NSWindowController {
    static let shared = HelpWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Octoshot Help"
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("OctoshotHelpWindow")

        let hosting = NSHostingController(rootView: HelpView())
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
