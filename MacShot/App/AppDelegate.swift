import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let hotkeyManager = HotkeyManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        SettingsOpener.installAccessoryRestoreOnClose()
        setupStatusItem()
        applyMenuBarVisibility()
        setupHotkeys()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHotkeysChanged),
            name: .macShotHotkeysDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMenuBarVisibilityChanged),
            name: .macShotMenuBarVisibilityDidChange,
            object: nil
        )

        PermissionManager.installActivationRefresh()
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await PermissionManager.presentInitialGuidanceIfNeeded()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.unregisterAll()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusItemImage()
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.addItem(menuItem("Capture Area", action: #selector(captureArea)))
        menu.addItem(menuItem("Capture Window", action: #selector(captureWindow)))
        menu.addItem(menuItem("Capture Fullscreen", action: #selector(captureFullscreen)))
        menu.addItem(.separator())
        let settingsItem = menuItem("Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = .command
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        menu.addItem(menuItem("Quit MacShot", action: #selector(quit), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    private func updateStatusItemImage() {
        guard let button = statusItem?.button else { return }
        if let image = NSImage(named: "MenuBarIcon") {
            image.isTemplate = true
            button.image = image
        } else {
            button.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "MacShot")
            button.image?.isTemplate = true
        }
    }

    private func applyMenuBarVisibility() {
        if AppSettings.shared.showMenuBarIcon {
            statusItem?.isVisible = true
        } else {
            statusItem?.isVisible = false
        }
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
        reregisterHotkeys()
    }

    @objc private func handleHotkeysChanged() {
        reregisterHotkeys()
    }

    @objc private func handleMenuBarVisibilityChanged() {
        applyMenuBarVisibility()
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

    private func reregisterHotkeys() {
        let settings = AppSettings.shared
        hotkeyManager.registerAll(
            area: settings.hotkeyArea,
            window: settings.hotkeyWindow,
            fullscreen: settings.hotkeyFullscreen
        )
    }

    @objc private func openSettings() {
        SettingsOpener.open()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
