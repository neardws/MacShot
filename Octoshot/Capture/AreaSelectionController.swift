import AppKit
import OctoshotCore

final class AreaSelectionController: NSResponder {
    var onComplete: ((CGRect, AreaCaptureMode) -> Void)?
    var onCancel: (() -> Void)?

    private(set) var captureMode: AreaCaptureMode = AppSettings.shared.rememberAreaCaptureMode
        ? AppSettings.shared.lastAreaCaptureMode
        : .screenshot

    private var overlayWindows: [AreaOverlayWindow] = []
    private var localMonitor: Any?
    private var globalKeyMonitor: Any?
    private var globalMouseMonitor: Any?
    private(set) var dragStart: NSPoint?
    private var currentPoint: NSPoint?
    private(set) var lastMouseGlobal: NSPoint = NSEvent.mouseLocation
    private(set) var lastSampledColor: ScreenColorInfo?
    private(set) var colorCopyHint: String?

    func begin() {
        end()
        lastMouseGlobal = NSEvent.mouseLocation
        for screen in NSScreen.screens {
            let window = AreaOverlayWindow(screen: screen)
            window.controller = self
            overlayWindows.append(window)
        }
        FullScreenOverlaySupport.presentCaptureOverlays(overlayWindows)

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .mouseMoved, .leftMouseDragged]) { [weak self] event in
            guard let self else { return event }
            if event.type == .keyDown, event.keyCode == 53 {
                cancel()
                return nil
            }
            if event.type == .keyDown, AppSettings.shared.developerModeEnabled,
               event.charactersIgnoringModifiers?.lowercased() == "c" {
                copyColorUnderCursor()
                return nil
            }
            if event.type == .keyDown,
               let char = event.charactersIgnoringModifiers,
               let mode = AreaCaptureMode.modeForModeBarKey(char) {
                captureMode = mode
                redrawAll()
                return nil
            }
            if event.type == .mouseMoved || event.type == .leftMouseDragged {
                lastMouseGlobal = NSEvent.mouseLocation
                refreshSampledColorIfNeeded()
                redrawAll()
            }
            return event
        }
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self else { return }
            if event.keyCode == 53 {
                cancel()
                return
            }
            if AppSettings.shared.developerModeEnabled,
               event.charactersIgnoringModifiers?.lowercased() == "c" {
                copyColorUnderCursor()
                return
            }
            if let char = event.charactersIgnoringModifiers,
               let mode = AreaCaptureMode.modeForModeBarKey(char) {
                captureMode = mode
                redrawAll()
            }
        }
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] _ in
            guard let self else { return }
            lastMouseGlobal = NSEvent.mouseLocation
            refreshSampledColorIfNeeded()
            focusWindowUnderMouse()
            redrawAll()
        }
        refreshSampledColorIfNeeded()
        redrawAll()
    }

    func refreshSampledColorIfNeeded() {
        guard AppSettings.shared.developerModeEnabled else {
            lastSampledColor = nil
            return
        }
        lastSampledColor = ScreenColorSampler.sample(at: lastMouseGlobal)
    }

    func copyColorUnderCursor() {
        guard AppSettings.shared.developerModeEnabled else { return }
        refreshSampledColorIfNeeded()
        guard let color = lastSampledColor else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(color.pasteboardText, forType: .string)
        colorCopyHint = "Copied \(color.hexRGB)"
        redrawAll()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.colorCopyHint = nil
            self?.redrawAll()
        }
    }

    func beginDrag(at point: NSPoint) {
        dragStart = point
        currentPoint = point
        redrawAll()
    }

    func updateSelection(start: NSPoint, current: NSPoint) {
        if dragStart == nil { dragStart = start }
        currentPoint = current
        lastMouseGlobal = current
        redrawAll()
    }

    func finishSelection(at point: NSPoint) {
        guard let start = dragStart else {
            cancel()
            return
        }
        let rect = DisplayGeometry.normalizedSelection(from: start, to: point)
        end()
        if rect.width >= 2, rect.height >= 2 {
            if AppSettings.shared.rememberAreaCaptureMode {
                AppSettings.shared.lastAreaCaptureMode = captureMode
            }
            onComplete?(rect, captureMode)
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

    func isDragging() -> Bool { dragStart != nil && currentPoint != nil }

    func setCaptureMode(_ mode: AreaCaptureMode) {
        captureMode = mode
        redrawAll()
    }

    func noteMousePosition(_ global: NSPoint) {
        lastMouseGlobal = global
        refreshSampledColorIfNeeded()
        redrawAll()
    }

    func redrawAll() {
        overlayWindows.forEach { $0.contentView?.needsDisplay = true }
    }

    private func focusWindowUnderMouse() {
        FullScreenOverlaySupport.focusOverlay(at: NSEvent.mouseLocation, in: overlayWindows)
    }

    private func end() {
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        if let globalKeyMonitor { NSEvent.removeMonitor(globalKeyMonitor) }
        if let globalMouseMonitor { NSEvent.removeMonitor(globalMouseMonitor) }
        localMonitor = nil
        globalKeyMonitor = nil
        globalMouseMonitor = nil
        overlayWindows.forEach { $0.orderOut(nil) }
        overlayWindows.removeAll()
        dragStart = nil
        currentPoint = nil
    }
}

final class AreaOverlayWindow: NSPanel {
    weak var controller: AreaSelectionController?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        setFrame(screen.frame, display: false)
        isOpaque = false
        backgroundColor = .clear
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
        FullScreenOverlaySupport.configureCaptureOverlayPanel(self)
        contentView = AreaOverlayView()
        (contentView as? AreaOverlayView)?.overlayWindow = self
    }
}

final class AreaOverlayView: NSView {
    weak var overlayWindow: AreaOverlayWindow?
    private var tracking: NSTrackingArea?

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .enabledDuringMouseDrag, .inVisibleRect, .cursorUpdate],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        tracking = area
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let controller = overlayWindow?.controller, let screen = overlayWindow?.screen else { return }
        let mouseGlobal = controller.lastMouseGlobal
        let mouseLocal = DisplayGeometry.flippedLocalPoint(cocoaGlobal: mouseGlobal, screen: screen)
        let mouseOnThisScreen = screen.frame.contains(mouseGlobal)

        if let selection = controller.selectionRectGlobal() {
            let dimPath = NSBezierPath(rect: bounds)
            let hole = DisplayGeometry.flippedLocalRect(cocoaGlobal: selection, screen: screen)
            dimPath.append(NSBezierPath(rect: hole))
            dimPath.windingRule = .evenOdd
            NSColor.black.withAlphaComponent(0.45).setFill()
            dimPath.fill()

            NSColor.systemBlue.setStroke()
            let border = NSBezierPath(roundedRect: hole, xRadius: 2, yRadius: 2)
            border.lineWidth = 2
            border.stroke()

            let label = "\(Int(selection.width)) × \(Int(selection.height))"
            drawLabel(label, near: labelPoint(for: hole))
            drawModeBar(below: hole, controller: controller)
        } else {
            NSColor.black.withAlphaComponent(0.28).setFill()
            bounds.fill()
        }

        if mouseOnThisScreen {
            drawCrosshair(at: mouseLocal)
            drawCursorLabel(at: mouseLocal, global: mouseGlobal, selection: controller.selectionRectGlobal())
            drawMagnifier(at: mouseLocal, global: mouseGlobal, controller: controller)
            if AppSettings.shared.developerModeEnabled, let hint = controller.colorCopyHint {
                drawLabel(hint, near: NSPoint(x: mouseLocal.x + 16, y: mouseLocal.y - 36))
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeKey()
        window?.makeFirstResponder(self)
        overlayWindow?.controller?.beginDrag(at: NSEvent.mouseLocation)
    }

    override func mouseDragged(with event: NSEvent) {
        let global = NSEvent.mouseLocation
        if let start = overlayWindow?.controller?.dragStart {
            overlayWindow?.controller?.updateSelection(start: start, current: global)
        }
    }

    override func mouseUp(with event: NSEvent) {
        overlayWindow?.controller?.finishSelection(at: NSEvent.mouseLocation)
    }

    override func mouseMoved(with event: NSEvent) {
        overlayWindow?.controller?.noteMousePosition(NSEvent.mouseLocation)
    }

    override func rightMouseDown(with event: NSEvent) {
        overlayWindow?.controller?.cancel()
    }

    private func drawCrosshair(at point: NSPoint) {
        NSColor.white.withAlphaComponent(0.85).setStroke()
        NSColor.black.withAlphaComponent(0.35).setStroke()

        let paths = [
            (NSPoint(x: point.x, y: 0), NSPoint(x: point.x, y: bounds.height)),
            (NSPoint(x: 0, y: point.y), NSPoint(x: bounds.width, y: point.y))
        ]
        for (start, end) in paths {
            let shadow = NSBezierPath()
            shadow.move(to: start)
            shadow.line(to: end)
            shadow.lineWidth = 1.5
            shadow.stroke()

            let line = NSBezierPath()
            line.move(to: start)
            line.line(to: end)
            line.lineWidth = 1
            NSColor.white.withAlphaComponent(0.9).setStroke()
            line.stroke()
        }
    }

    private func drawCursorLabel(at local: NSPoint, global: NSPoint, selection: CGRect?) {
        let text: String
        if let selection {
            text = "\(Int(selection.width)) × \(Int(selection.height)) px"
        } else {
            text = "x: \(Int(global.x))  y: \(Int(global.y))"
        }
        let offset = NSPoint(x: local.x + 16, y: local.y + 16)
        drawLabel(text, near: offset)
    }

    private func labelPoint(for rect: CGRect) -> NSPoint {
        NSPoint(x: min(rect.maxX + 8, bounds.width - 120), y: max(rect.minY - 28, 8))
    }

    private func drawModeBar(below rect: CGRect, controller: AreaSelectionController) {
        let modes: [AreaCaptureMode] = [.screenshot, .scrolling, .recordVideo, .recordGIF, .formulaLaTeX, .figureTable]
        let labels = modes.map { mode -> String in
            let active = controller.captureMode == mode
            return active ? "[\(mode.modeBarLabel)]" : mode.modeBarLabel
        }
        let text = labels.joined(separator: "  ")
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        let size = (text as NSString).size(withAttributes: attributes)
        let barWidth = size.width + 20
        let barHeight = size.height + 10
        let x = min(max(rect.minX, 8), bounds.width - barWidth - 8)
        let y = max(rect.minY - barHeight - 8, 8)
        let barRect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
        let bg = NSBezierPath(roundedRect: barRect, xRadius: 8, yRadius: 8)
        NSColor.black.withAlphaComponent(0.78).setFill()
        bg.fill()
        (text as NSString).draw(in: barRect.insetBy(dx: 10, dy: 5), withAttributes: attributes)
    }

    private func drawLabel(_ text: String, near point: NSPoint) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let size = (text as NSString).size(withAttributes: attributes)
        let rect = CGRect(x: point.x, y: point.y, width: size.width + 12, height: size.height + 8)
        let bg = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)
        NSColor.black.withAlphaComponent(0.72).setFill()
        bg.fill()
        (text as NSString).draw(in: rect.insetBy(dx: 6, dy: 4), withAttributes: attributes)
    }

    private func drawMagnifier(at local: NSPoint, global: NSPoint, controller: AreaSelectionController) {
        let loupeSize: CGFloat = 96
        let zoom: CGFloat = 6
        let sampleSize = loupeSize / zoom
        guard let screen = overlayWindow?.screen else { return }

        let sampleGlobal = CGRect(
            x: global.x - sampleSize / 2,
            y: global.y - sampleSize / 2,
            width: sampleSize,
            height: sampleSize
        )
        guard let cgImage = CGWindowListCreateImage(
            sampleGlobal,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        ) else { return }

        let loupeOrigin = NSPoint(
            x: min(max(8, local.x + 20), bounds.width - loupeSize - 8),
            y: min(max(8, local.y + 20), bounds.height - loupeSize - 8)
        )
        let loupeRect = CGRect(origin: loupeOrigin, size: CGSize(width: loupeSize, height: loupeSize))
        let image = NSImage(cgImage: cgImage, size: NSSize(width: sampleSize, height: sampleSize))
        NSGraphicsContext.saveGraphicsState()
        let clip = NSBezierPath(roundedRect: loupeRect, xRadius: 8, yRadius: 8)
        clip.addClip()
        image.draw(in: loupeRect)
        NSGraphicsContext.restoreGraphicsState()

        NSColor.white.withAlphaComponent(0.9).setStroke()
        let border = NSBezierPath(roundedRect: loupeRect, xRadius: 8, yRadius: 8)
        border.lineWidth = 2
        border.stroke()

        if AppSettings.shared.developerModeEnabled, let color = controller.lastSampledColor {
            let swatch = CGRect(x: loupeRect.minX + 6, y: loupeRect.maxY - 18, width: 12, height: 12)
            NSColor(
                red: CGFloat(color.red) / 255,
                green: CGFloat(color.green) / 255,
                blue: CGFloat(color.blue) / 255,
                alpha: 1
            ).setFill()
            NSBezierPath(ovalIn: swatch).fill()

            let colorLine = "\(color.hexRGB)  \(color.rgbText)"
            let labelY = loupeRect.maxY + 6
            let labelX = min(loupeRect.minX, bounds.width - 220)
            drawLabel(colorLine, near: NSPoint(x: labelX, y: labelY))
            if controller.colorCopyHint == nil {
                drawLabel("Press C to copy", near: NSPoint(x: labelX, y: labelY + 26))
            }
        }
    }
}
