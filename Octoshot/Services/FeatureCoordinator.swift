import AppKit
import OctoshotCore

@MainActor
final class FeatureCoordinator {
    static let shared = FeatureCoordinator()

    private let latexWindow = LaTeXResultWindowController()

    func showLaTeX(with image: NSImage) {
        latexWindow.show(image: image)
    }

    func startLaTeXAreaCapture() {
        CaptureFollowUpState.shared.areaFollowUp = .latex
        CaptureCoordinator.shared.startAreaCapture()
    }

    func startPaperClipAreaCapture() {
        CaptureFollowUpState.shared.areaFollowUp = .paperClip
        CaptureCoordinator.shared.startAreaCapture()
    }
}
