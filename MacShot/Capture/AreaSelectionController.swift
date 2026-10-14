import AppKit

final class AreaSelectionController: NSResponder {
    var onComplete: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var overlayWindows: [AreaOverlayWindow] = []
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private(set) var dragStart: NSPoint?
    private var currentPoint: NSPoint?
    private var isDragging = false

    func begin() {
        end()
        for screen in NSScreen.screens {
            let window = AreaOverlayWindow(screen: screen)
            window.controller = self
            window.makeKeyAndOrderFront(nil)
            overlayWindows.append(window)
        }
        NSApp.activate(ignoringOtherApps: true)

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.keyCode == 53 { // ESC
                self?.cancel()
                return nil
            }
            return event
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.keyCode == 53 {
                self?.cancel()
            }
        }
    }

    func beginDrag(at point: NSPoint) {
        dragStart = point
        currentPoint = point
        isDragging = true
        overlayWindows.forEach { $0.needsDisplay = true }
    }

    func updateSelection(start: NSPoint, current: NSPoint, dragging: Bool) {
        if dragStart == nil { dragStart = start }
        currentPoint = current
        isDragging = dragging
        overlayWindows.forEach { $0.needsDisplay = true }
    }

    func finishSelection(at point: NSPoint) {
        guard let start = dragStart else {
            cancel()
            return
        }
        let rect = DisplayGeometry.normalizedSelection(from: start, to: point)
        end()
        if rect.width >= 2, rect.height >= 2 {
            onComplete?(rect)
        } else {
            onCancel?()
        }
    }

    func cancel() {
        end()
        onCancel?()
    }

    func selectionRectGlobal() -> CGRect? {
        guard let start = dragStart, let current = currentPoint else { return nil }
        return DisplayGeometry.normalizedSelection(from: start, to: current)
    }

    func mouseLocation() -> NSPoint {
        NSEvent.mouseLocation
    }

    private func end() {
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        localMonitor = nil
        globalMonitor = nil
        overlayWindows.forEach { $0.orderOut(nil) }
        overlayWindows.removeAll()
        dragStart = nil
        currentPoint = nil
        isDragging = false
    }
}

final class AreaOverlayWindow: NSWindow {
    weak var controller: AreaSelectionController?

    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        isOpaque = false
        backgroundColor = NSColor.black.withAlphaComponent(0.25)
        level = .screenSaver
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        contentView = AreaOverlayView()
        (contentView as? AreaOverlayView)?.overlayWindow = self
    }
}

final class AreaOverlayView: NSView {
    weak var overlayWindow: AreaOverlayWindow?
    private var tracking: NSTrackingArea?

    override var acceptsFirstResponder: Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .enabledDuringMouseDrag, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        tracking = area
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let controller = overlayWindow?.controller else { return }
        let mouse = convertMouseToGlobal()

        NSColor.black.withAlphaComponent(0.35).setFill()
        bounds.fill()

        if let selection = controller.selectionRectGlobal(),
           let window = overlayWindow,
           let screen = window.screen {
            let local = selection.offsetBy(dx: -screen.frame.origin.x, dy: -screen.frame.origin.y)
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
            path.lineWidth = 2
            path.stroke()

            let label = "\(Int(selection.width)) × \(Int(selection.height))"
            drawLabel(label, near: NSPoint(x: flipped.maxX + 8, y: flipped.maxY - 20))
        }

        drawCrosshair(at: convertGlobalToLocal(mouse))
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        overlayWindow?.controller?.beginDrag(at: convertMouseToGlobal())
    }

    override func mouseDragged(with event: NSEvent) {
        let global = convertMouseToGlobal()
        if let start = overlayWindow?.controller?.dragStart {
            overlayWindow?.controller?.updateSelection(start: start, current: global, dragging: true)
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        overlayWindow?.controller?.finishSelection(at: convertMouseToGlobal())
    }

    override func mouseMoved(with event: NSEvent) {
        needsDisplay = true
    }

    override func rightMouseDown(with event: NSEvent) {
        overlayWindow?.controller?.cancel()
    }

    private func convertMouseToGlobal() -> NSPoint {
        let local = convert(eventLocation(), from: nil)
        let windowPoint = convert(local, to: nil)
        guard let screen = window?.screen else { return windowPoint }
        return NSPoint(
            x: windowPoint.x + screen.frame.origin.x,
            y: windowPoint.y + screen.frame.origin.y
        )
    }

    private func eventLocation() -> NSPoint {
        window?.mouseLocationOutsideOfEventStream ?? .zero
    }

    private func convertGlobalToLocal(_ global: NSPoint) -> NSPoint {
        guard let screen = window?.screen else { return global }
        let windowPoint = NSPoint(
            x: global.x - screen.frame.origin.x,
            y: global.y - screen.frame.origin.y
        )
        return NSPoint(x: windowPoint.x, y: bounds.height - windowPoint.y)
    }

    private func drawCrosshair(at point: NSPoint) {
        NSColor.white.withAlphaComponent(0.9).setStroke()
        let v = NSBezierPath()
        v.move(to: NSPoint(x: point.x, y: 0))
        v.line(to: NSPoint(x: point.x, y: bounds.height))
        v.lineWidth = 1
        v.stroke()

        let h = NSBezierPath()
        h.move(to: NSPoint(x: 0, y: point.y))
        h.line(to: NSPoint(x: bounds.width, y: point.y))
        h.lineWidth = 1
        h.stroke()
    }

    private func drawLabel(_ text: String, near point: NSPoint) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.black.withAlphaComponent(0.65)
        ]
        let size = (text as NSString).size(withAttributes: attributes)
        let rect = CGRect(x: point.x, y: point.y, width: size.width + 8, height: size.height + 4)
        (text as NSString).draw(in: rect.insetBy(dx: 4, dy: 2), withAttributes: attributes)
    }
}
