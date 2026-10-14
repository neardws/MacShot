import AppKit
import ScreenCaptureKit

@MainActor
final class CaptureCoordinator {
    static let shared = CaptureCoordinator()

    private let areaSelection = AreaSelectionController()
    private let windowSelection = WindowSelectionController()
    private let quickAccess = QuickAccessPanelController()
    private let annotation = AnnotationWindowController()

    private var isCapturing = false

    private init() {
        areaSelection.onComplete = { [weak self] rect in
            Task { await self?.performRegionCapture(rect) }
        }
        areaSelection.onCancel = { [weak self] in self?.isCapturing = false }

        windowSelection.onComplete = { [weak self] window in
            Task { await self?.performWindowCapture(window) }
        }
        windowSelection.onCancel = { [weak self] in self?.isCapturing = false }
    }

    func startAreaCapture() {
        guard beginCaptureFlow() else { return }
        areaSelection.begin()
    }

    func startWindowCapture() {
        guard beginCaptureFlow() else { return }
        Task {
            do {
                let content = try await ScreenCaptureService.shared.shareableContent()
                let appWindows = content.windows.filter { window in
                    window.owningApplication?.bundleIdentifier != Bundle.main.bundleIdentifier
                }
                windowSelection.begin(windows: appWindows)
            } catch {
                finishWithError(error)
            }
        }
    }

    func startFullscreenCapture() {
        guard beginCaptureFlow() else { return }
        Task { await performFullscreenCapture() }
    }

    private func beginCaptureFlow() -> Bool {
        if isCapturing { return false }
        guard PermissionManager.ensureScreenRecordingAccess(promptIfNeeded: true) else {
            return false
        }
        isCapturing = true
        return true
    }

    private func performRegionCapture(_ rect: CGRect) async {
        defer { isCapturing = false }
        do {
            let image = try await ScreenCaptureService.shared.captureRegion(globalRect: rect)
            presentResult(image)
        } catch {
            finishWithError(error)
        }
    }

    private func performWindowCapture(_ window: SCWindow) async {
        defer { isCapturing = false }
        do {
            let image = try await ScreenCaptureService.shared.captureWindow(window)
            presentResult(image)
        } catch {
            finishWithError(error)
        }
    }

    private func performFullscreenCapture() async {
        defer { isCapturing = false }
        do {
            let mouse = NSEvent.mouseLocation
            let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
            let content = try await ScreenCaptureService.shared.shareableContent()
            let display = content.displays.first { $0.displayID == screen?.displayID } ?? content.displays.first
            let image = try await ScreenCaptureService.shared.captureFullscreen(display: display)
            presentResult(image)
        } catch {
            finishWithError(error)
        }
    }

    private func presentResult(_ image: NSImage) {
        quickAccess.show(image: image, actions: QuickAccessActions(
            onCopy: { ImageFormats.copyToPasteboard(image) },
            onSave: {
                let url = AppSettings.shared.defaultSaveURL()
                do {
                    try ImageFormats.write(
                        image: image,
                        to: url,
                        format: AppSettings.shared.format,
                        jpegQuality: AppSettings.shared.jpegQuality
                    )
                } catch {
                    self.finishWithError(error)
                }
            },
            onAnnotate: { self.annotation.open(with: image) },
            onClose: { self.quickAccess.closePanel() }
        ))
    }

    private func finishWithError(_ error: Error) {
        isCapturing = false
        let alert = NSAlert(error: error)
        alert.runModal()
    }
}

private extension NSScreen {
    var displayID: CGDirectDisplayID {
        guard let number = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return 0
        }
        return CGDirectDisplayID(number.uint32Value)
    }
}
