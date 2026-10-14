import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let hotkeyManager = HotkeyManager()
    private let preferences = PreferencesWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupHotkeys()

        if !PermissionManager.hasScreenRecordingAccess {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                PermissionManager.ensureScreenRecordingAccess(promptIfNeeded: true)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.unregisterAll()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "MacShot")
            button.image?.isTemplate = true
        }

        let menu = NSMenu()
        menu.addItem(menuItem("Capture Area", action: #selector(captureArea)))
        menu.addItem(menuItem("Capture Window", action: #selector(captureWindow)))
        menu.addItem(menuItem("Capture Fullscreen", action: #selector(captureFullscreen)))
        menu.addItem(.separator())
        menu.addItem(menuItem("Preferences…", action: #selector(openPreferences)))
        menu.addItem(.separator())
        menu.addItem(menuItem("Quit MacShot", action: #selector(quit), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    private func menuItem(_ title: String, action: Selector, keyEquivalent: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    private func setupHotkeys() {
        hotkeyManager.onHotkey = { [weak self] action in
            switch action {
            case .area: self?.captureArea()
            case .window: self?.captureWindow()
            case .fullscreen: self?.captureFullscreen()
            }
        }
        hotkeyManager.registerAll(from: AppSettings.shared)
    }

    @objc private func captureArea() {
        CaptureCoordinator.shared.startAreaCapture()
    }

    @objc private func captureWindow() {
        CaptureCoordinator.shared.startWindowCapture()
    }

    @objc private func captureFullscreen() {
        CaptureCoordinator.shared.startFullscreenCapture()
    }

    @objc private func openPreferences() {
        preferences.show { [weak self] in
            self?.hotkeyManager.registerAll(from: AppSettings.shared)
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
