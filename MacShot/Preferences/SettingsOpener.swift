import AppKit

@MainActor
enum SettingsOpener {
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
            let title = window.title.lowercased()
            guard title.contains("settings") || title.contains("macshot") else { return }
            if NSApp.activationPolicy() == .regular {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }

    static func open() {
        installAccessoryRestoreOnClose()
        if NSApp.activationPolicy() == .accessory {
            NSApp.setActivationPolicy(.regular)
        }
        NSApp.activate(ignoringOtherApps: true)

        let showSettings = Selector(("showSettingsWindow:"))
        if NSApp.responds(to: showSettings) {
            NSApp.sendAction(showSettings, to: nil, from: nil)
        }
        bringSettingsWindowToFront()
    }

    private static func bringSettingsWindowToFront() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let settingsWindow = NSApp.windows.first { window in
                let title = window.title.lowercased()
                return title.contains("settings") || title.contains("macshot")
            }
            settingsWindow?.makeKeyAndOrderFront(nil)
            settingsWindow?.orderFrontRegardless()
        }
    }
}
