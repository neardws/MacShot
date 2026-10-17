import AppKit
import OctoshotCore

enum ScreenshotHotkeyConflictStore {
    private static let suppressKey = "suppressScreenshotHotkeyConflictAlert"

    static var shouldShowAlert: Bool {
        !UserDefaults.standard.bool(forKey: suppressKey)
    }

    static func setSuppressFutureAlerts(_ suppress: Bool) {
        UserDefaults.standard.set(suppress, forKey: suppressKey)
    }
}

@MainActor
enum ScreenshotHotkeyConflictPresenter {
    /// Presents conflict UI when system screenshot shortcuts overlap Octoshot bindings.
    static func presentIfNeeded(origin: ConflictAlertOrigin) {
        guard ScreenshotHotkeyConflictStore.shouldShowAlert else { return }
        let conflicts = SystemScreenshotHotkeys.conflicts()
        guard !conflicts.isEmpty else { return }
        present(conflicts: conflicts, origin: origin)
    }

    enum ConflictAlertOrigin {
        case launch
        case onboarding
    }

    static func present(conflicts: [SystemScreenshotHotkeys.Entry], origin: ConflictAlertOrigin) {
        let alert = NSAlert()
        alert.messageText = OctoshotL10n.systemHotkeyConflictTitle
        alert.informativeText = conflictBody(conflicts: conflicts, origin: origin)
        alert.alertStyle = .warning
        alert.addButton(withTitle: OctoshotL10n.systemHotkeyDisableAction)
        alert.addButton(withTitle: OctoshotL10n.systemHotkeyOpenSettingsAction)
        alert.addButton(withTitle: OctoshotL10n.systemHotkeyDismissAction)
        alert.showsSuppressionButton = true
        alert.suppressionButton?.title = OctoshotL10n.systemHotkeySuppressFuture

        let response = alert.runModal()
        if alert.suppressionButton?.state == .on {
            ScreenshotHotkeyConflictStore.setSuppressFutureAlerts(true)
        }

        switch response {
        case .alertFirstButtonReturn:
            confirmAndDisableSystemHotkeys()
        case .alertSecondButtonReturn:
            SystemScreenshotHotkeys.applyOctoshotTakeover()
            SystemScreenshotHotkeys.openKeyboardSettings()
        default:
            break
        }
    }

    private static func conflictBody(
        conflicts: [SystemScreenshotHotkeys.Entry],
        origin: ConflictAlertOrigin
    ) -> String {
        let keys = conflicts.map { HotkeyFormatter.displayString(for: $0.binding) }
        let joined = keys.joined(separator: ", ")
        switch origin {
        case .launch:
            return String(format: OctoshotL10n.systemHotkeyConflictLaunchBody, joined)
        case .onboarding:
            return String(format: OctoshotL10n.systemHotkeyConflictOnboardingBody, joined)
        }
    }

    @discardableResult
    static func confirmAndDisableSystemHotkeys() -> Bool {
        let confirm = NSAlert()
        confirm.messageText = OctoshotL10n.systemHotkeyDisableConfirmTitle
        confirm.informativeText = OctoshotL10n.systemHotkeyDisableConfirmBody
        confirm.alertStyle = .warning
        confirm.addButton(withTitle: OctoshotL10n.systemHotkeyDisableAction)
        confirm.addButton(withTitle: OctoshotL10n.cancel)
        guard confirm.runModal() == .alertFirstButtonReturn else { return false }
        do {
            try SystemScreenshotHotkeys.disableSystemScreenshotHotkeys()
            return true
        } catch {
            let errorAlert = NSAlert()
            errorAlert.messageText = OctoshotL10n.systemHotkeyDisableFailedTitle
            errorAlert.informativeText = error.localizedDescription
            errorAlert.runModal()
            return false
        }
    }
}
