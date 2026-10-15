import AppKit
import ScreenCaptureKit
import SwiftUI

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
        Task {
            guard await beginCaptureFlow() else { return }
            areaSelection.begin()
        }
    }

    func startWindowCapture() {
        Task {
            guard await beginCaptureFlow() else { return }
            do {
                let content = try await ScreenCaptureService.shared.shareableContent()
                ScreenRecordingAccessCache.shared.lastKnownGranted = true
                let appWindows = ShareableWindowFilter.pickableWindows(from: content)
                windowSelection.begin(windows: appWindows)
            } catch {
                await PermissionManager.handleCaptureFailure(error)
                finishWithError(error)
            }
        }
    }

    func startFullscreenCapture() {
        Task { await performFullscreenCapture() }
    }

    private func beginCaptureFlow() async -> Bool {
        if isCapturing { return false }
        await PermissionManager.prepareForCaptureIfNeeded()
        isCapturing = true
        return true
    }

    private func performRegionCapture(_ rect: CGRect) async {
        defer { isCapturing = false }
        do {
            let image = try await ScreenCaptureService.shared.captureRegion(globalRect: rect)
            ScreenRecordingAccessCache.shared.lastKnownGranted = true
            await handleRegionCaptureResult(image)
        } catch {
            await PermissionManager.handleCaptureFailure(error)
            finishWithError(error)
        }
    }

    private func handleRegionCaptureResult(_ image: NSImage) async {
        let followUp = CaptureFollowUpState.shared.areaFollowUp
        CaptureFollowUpState.shared.areaFollowUp = .standard
        switch followUp {
        case .standard:
            presentResult(image)
        case .latex:
            CaptureFeedback.playCaptureSoundIfEnabled()
            FeatureCoordinator.shared.showLaTeX(with: image)
        case .paperClip:
            presentResult(image)
            Task {
                do {
                    let folder = try await PaperClipService.processFigure(image: image)
                    let alert = NSAlert()
                    alert.messageText = "Saved to Clips Library"
                    alert.informativeText = folder.path
                    alert.runModal()
                } catch {
                    finishWithError(error)
                }
            }
        }
    }

    private func performWindowCapture(_ window: SCWindow) async {
        defer { isCapturing = false }
        do {
            let image = try await ScreenCaptureService.shared.captureWindow(window)
            ScreenRecordingAccessCache.shared.lastKnownGranted = true
            presentResult(image)
        } catch {
            await PermissionManager.handleCaptureFailure(error)
            finishWithError(error)
        }
    }

    private func performFullscreenCapture() async {
        guard await beginCaptureFlow() else { return }
        defer { isCapturing = false }
        do {
            let mouse = NSEvent.mouseLocation
            let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
            let content = try await ScreenCaptureService.shared.shareableContent()
            let display = content.displays.first { $0.displayID == screen?.displayID } ?? content.displays.first
            let image = try await ScreenCaptureService.shared.captureFullscreen(display: display)
            ScreenRecordingAccessCache.shared.lastKnownGranted = true
            presentResult(image)
        } catch {
            await PermissionManager.handleCaptureFailure(error)
            finishWithError(error)
        }
    }

    private func presentResult(_ image: NSImage) {
        CaptureFeedback.playCaptureSoundIfEnabled()
        let settings = AppSettings.shared

        if settings.afterCaptureCopyToClipboard {
            ImageFormats.copyToPasteboard(image)
        }

        if settings.afterCaptureSaveToDisk {
            let url = settings.defaultSaveURL()
            do {
                try ImageFormats.write(
                    image: image,
                    to: url,
                    format: settings.format,
                    jpegQuality: settings.jpegQuality
                )
            } catch {
                finishWithError(error)
            }
        }

        guard settings.afterCaptureShowQuickAccess else { return }

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
            onAskAI: { self.showAI(for: image) },
            onClose: {}
        ))
    }

    private func showAI(for image: NSImage) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 480),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Ask Local AI"
        panel.isFloatingPanel = true
        panel.contentView = NSHostingView(rootView: AIAssistantPanelView(image: image))
        panel.center()
        panel.makeKeyAndOrderFront(nil)
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
