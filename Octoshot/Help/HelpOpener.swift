import AppKit

@MainActor
enum HelpOpener {
    private static var didInstallCloseObserver = false

    static func installAccessoryRestoreOnClose() {
        guard !didInstallCloseObserver else { return }
        didInstallCloseObserver = true
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let window = notification.object as? NSWindow else { return }
            guard window.title == "Octoshot Help" else { return }
            if NSApp.activationPolicy() == .regular,
               !SettingsWindowController.shared.windowIsVisible {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }

    static func open() {
        installAccessoryRestoreOnClose()
        HelpWindowController.shared.show()
    }
}

extension SettingsWindowController {
    var windowIsVisible: Bool {
        window?.isVisible == true
    }
}
