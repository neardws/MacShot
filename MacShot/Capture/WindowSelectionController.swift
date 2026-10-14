import AppKit
import ScreenCaptureKit

final class WindowSelectionController {
    var onComplete: ((SCWindow) -> Void)?
    var onCancel: (() -> Void)?

    private var overlayWindows: [WindowOverlayWindow] = []
    private var windows: [SCWindow] = []
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var highlighted: SCWindow?

    func begin(windows: [SCWindow]) {
        end()
        self.windows = windows.filter { $0.isOnScreen && $0.frame.width > 40 && $0.frame.height > 40 }
        for screen in NSScreen.screens {
            let window = WindowOverlayWindow(screen: screen)
            window.controller = self
            window.makeKeyAndOrderFront(nil)
            overlayWindows.append(window)
        }
        NSApp.activate(ignoringOtherApps: true)

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.keyCode == 53 {
                self?.cancel()
                return nil
            }
            return event
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.keyCode == 53 { self?.cancel() }
        }
    }

    func windowAtGlobalPoint(_ point: NSPoint) -> SCWindow? {
        let sorted = windows.sorted { $0.windowLayer > $1.windowLayer }
        return sorted.first { window in
            DisplayGeometry.cocoaRect(fromTopLeftFrame: window.frame).contains(point)
        }
    }

    func setHighlighted(_ window: SCWindow?) {
        highlighted = window
        overlayWindows.forEach { $0.contentView?.needsDisplay = true }
    }

    func select(_ window: SCWindow) {
        end()
        onComplete?(window)
    }

    func cancel() {
        end()
        onCancel?()
    }

    func highlightedWindow() -> SCWindow? { highlighted }

    private func end() {
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        localMonitor = nil
        globalMonitor = nil
        overlayWindows.forEach { $0.orderOut(nil) }
        overlayWindows.removeAll()
        highlighted = nil
    }
}

final class WindowOverlayWindow: NSWindow {
    weak var controller: WindowSelectionController?

    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        isOpaque = false
        backgroundColor = .clear
        level = .screenSaver
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        contentView = WindowOverlayView()
        (contentView as? WindowOverlayView)?.overlayWindow = self
    }
}

final class WindowOverlayView: NSView {
    weak var overlayWindow: WindowOverlayWindow?

    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.2).setFill()
        bounds.fill()

        guard let controller = overlayWindow?.controller,
              let window = controller.highlightedWindow(),
              let screen = overlayWindow?.screen else { return }

        let global = DisplayGeometry.cocoaRect(fromTopLeftFrame: window.frame)
        let local = global.offsetBy(dx: -screen.frame.origin.x, dy: -screen.frame.origin.y)
        let flipped = CGRect(
            x: local.origin.x,
            y: bounds.height - local.origin.y - local.height,
            width: local.width,
            height: local.height
        )
        NSColor.clear.setFill()
        flipped.fill(using: .copy)
        NSColor.systemBlue.setStroke()
        let path = NSBezierPath(rect: flipped)
        path.lineWidth = 3
        path.stroke()

        let title = window.title ?? "Window"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.systemBlue
        ]
        (title as NSString).draw(at: NSPoint(x: flipped.minX + 6, y: flipped.maxY - 22), withAttributes: attributes)
    }

    override func mouseMoved(with event: NSEvent) {
        updateHighlight()
    }

    override func mouseDown(with event: NSEvent) {
        if let window = overlayWindow?.controller?.windowAtGlobalPoint(globalMouse()) {
            overlayWindow?.controller?.select(window)
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        overlayWindow?.controller?.cancel()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .enabledDuringMouseDrag, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }

    private func updateHighlight() {
        overlayWindow?.controller?.setHighlighted(
            overlayWindow?.controller?.windowAtGlobalPoint(globalMouse())
        )
        needsDisplay = true
    }

    private func globalMouse() -> NSPoint {
        NSEvent.mouseLocation
    }
}
