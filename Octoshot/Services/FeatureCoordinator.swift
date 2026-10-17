import AppKit
import OctoshotCore

@MainActor
final class FeatureCoordinator {
    static let shared = FeatureCoordinator()

    private let latexWindow = LaTeXResultWindowController()
    private let ocrWindow = OCRResultWindowController()

    func showLaTeX(with image: NSImage) {
        latexWindow.show(image: image)
    }

    func showOCR(with image: NSImage) {
        ocrWindow.show(image: image)
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
