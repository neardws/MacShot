import AppKit
import OctoshotCore

@MainActor
final class HotkeyRecorder {
    static let shared = HotkeyRecorder()
    private var monitor: Any?

    func start(handler: @escaping (NSEvent) -> Void) {
        stop()
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            if event.modifierFlags.intersection([.command, .shift, .option, .control]).isEmpty {
                return event
            }
            handler(event)
            return nil
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}
