import AppKit
import OctoshotCore

@MainActor
final class HotkeyRecorder {
    static let shared = HotkeyRecorder()
    private var monitor: Any?
    private var cancelHandler: (() -> Void)?

    func start(
        onRecord: @escaping (NSEvent) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        stop()
        cancelHandler = onCancel
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            if event.keyCode == UInt16(HotkeyKeyCode.escape) {
                Task { @MainActor in
                    HotkeyRecorder.shared.cancelHandler?()
                    HotkeyRecorder.shared.stop()
                }
                return nil
            }
            if event.modifierFlags.intersection([.command, .shift, .option, .control]).isEmpty {
                return event
            }
            onRecord(event)
            return nil
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        cancelHandler = nil
    }
}
