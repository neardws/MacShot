import AppKit

enum CaptureFeedback {
    static func playCaptureSoundIfEnabled() {
        guard AppSettings.shared.playCaptureSound else { return }
        if let sound = NSSound(named: NSSound.Name("Tink")) {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
}
