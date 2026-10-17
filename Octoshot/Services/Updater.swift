import AppKit
import Sparkle

/// Sparkle 2 in-app updates. Only starts inside a signed `.app` bundle when `SUFeedURL` is set.
/// Debug / non-bundle runs skip Sparkle so missing feed keys do not surface errors.
@MainActor
final class Updater: NSObject {
    static let shared = Updater()
    private let controller: SPUStandardUpdaterController?

    private override init() {
        let bundled = Bundle.main.bundlePath.hasSuffix(".app")
            && Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") != nil
        controller = bundled
            ? SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
            : nil
        super.init()
    }

    var automaticallyChecksForUpdates: Bool {
        get { controller?.updater.automaticallyChecksForUpdates ?? true }
        set { controller?.updater.automaticallyChecksForUpdates = newValue }
    }

    func checkForUpdates() {
        controller?.checkForUpdates(nil)
    }
}
