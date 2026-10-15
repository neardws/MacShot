import AppKit
import CoreImage

final class AnnotationCanvasView: NSView {
    var baseImage: NSImage? {
        didSet { rebuildComposite(); needsDisplay = true }
    }

    var strokes: [AnnotationStroke] = [] {
        didSet { rebuildComposite(); needsDisplay = true }
    }

    var redactionRegions: [CGRect] = [] {
        didSet { rebuildComposite(); needsDisplay = true }
    }

    var previewRedactions: [RedactionCandidate] = [] {
        didSet { needsDisplay = true }
    }

    var activeTool: AnnotationTool = .arrow
    var strokeColor: NSColor = .systemRed
    var lineWidth: CGFloat = 4

    private var dragStart: CGPoint?
    private var inProgress: AnnotationStroke?
    private var measureStart: CGPoint?
    private var measureEnd: CGPoint?
    private var renderedImage: NSImage?

    var onStrokesChanged: (() -> Void)?

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        if let renderedImage {
            renderedImage.draw(in: bounds)
        } else if let baseImage {
            baseImage.draw(in: bounds)
        }
        if let inProgress {
            drawStroke(inProgress, in: bounds)
        }
        for candidate in previewRedactions where candidate.isEnabled {
            let path = NSBezierPath(rect: mapImageRectToView(candidate.rect))
            NSColor.systemRed.withAlphaComponent(0.25).setFill()
            path.fill()
            NSColor.systemRed.setStroke()
            path.lineWidth = 1.5
            path.stroke()
        }
        if let start = measureStart, let end = measureEnd {
            drawMeasureOverlay(from: start, to: end)
        }
    }

    func applyRedactions(from candidates: [RedactionCandidate]) {
        redactionRegions = candidates.filter(\.isEnabled).map(\.rect)
        previewRedactions = []
        rebuildComposite()
        needsDisplay = true
    }

    private func mapImageRectToView(_ rect: CGRect) -> CGRect {
        guard let baseImage else { return rect }
        let sx = bounds.width / max(baseImage.size.width, 1)
        let sy = bounds.height / max(baseImage.size.height, 1)
        return CGRect(x: rect.origin.x * sx, y: rect.origin.y * sy, width: rect.width * sx, height: rect.height * sy)
    }

    private func mapViewPointToImage(_ point: CGPoint) -> CGPoint {
        guard let baseImage else { return point }
        let sx = max(baseImage.size.width, 1) / bounds.width
        let sy = max(baseImage.size.height, 1) / bounds.height
        return CGPoint(x: point.x * sx, y: point.y * sy)
    }

    private func imagePixelScale() -> CGFloat {
        guard let baseImage,
              let cg = baseImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return 1 }
        return CGFloat(cg.width) / max(baseImage.size.width, 1)
    }

    private func drawMeasureOverlay(from start: CGPoint, to end: CGPoint) {
        let box = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        NSColor.systemTeal.setStroke()
        let path = NSBezierPath(rect: box)
        path.lineWidth = 1.5
        path.stroke()

        let startImage = mapViewPointToImage(start)
        let endImage = mapViewPointToImage(end)
        let widthPt = abs(endImage.x - startImage.x)
        let heightPt = abs(endImage.y - startImage.y)
        let scale = imagePixelScale()
        let widthPx = widthPt * scale
        let heightPx = heightPt * scale
        let diagonalPt = hypot(widthPt, heightPt)
        let diagonalPx = diagonalPt * scale

        let lines = [
            String(format: "%.0f × %.0f px  (%.1f × %.1f pt)", widthPx, heightPx, widthPt, heightPt),
            String(format: "↳ %.1f px diagonal", diagonalPx)
        ]
        let text = lines.joined(separator: "\n")
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let size = (text as NSString).size(withAttributes: attributes)
        let origin = NSPoint(x: box.minX + 4, y: min(box.maxY + 6, bounds.height - size.height - 12))
        let bg = NSBezierPath(roundedRect: CGRect(origin: origin, size: CGSize(width: size.width + 10, height: size.height + 8)), xRadius: 6, yRadius: 6)
        NSColor.black.withAlphaComponent(0.72).setFill()
        bg.fill()
        (text as NSString).draw(in: CGRect(origin: origin, size: size).insetBy(dx: 5, dy: 4), withAttributes: attributes)
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if activeTool == .measure {
            measureStart = point
            measureEnd = point
            needsDisplay = true
            return
        }
        dragStart = point
    }

    override func mouseDragged(with event: NSEvent) {
        let current = convert(event.locationInWindow, from: nil)
        if activeTool == .measure {
            measureEnd = current
            needsDisplay = true
            return
        }
        guard let start = dragStart else { return }
        inProgress = AnnotationStroke(
            tool: activeTool,
            start: start,
            end: current,
            text: "",
            color: strokeColor,
            lineWidth: lineWidth
        )
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let end = convert(event.locationInWindow, from: nil)
        if activeTool == .measure {
            measureEnd = end
            needsDisplay = true
            return
        }
        guard let start = dragStart else { return }
        dragStart = nil
        inProgress = nil
        commitStroke(from: start, to: end)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53, measureStart != nil {
            measureStart = nil
            measureEnd = nil
            needsDisplay = true
            return
        }
        super.keyDown(with: event)
    }

    override var acceptsFirstResponder: Bool { true }

    func undo() {
        guard !strokes.isEmpty else { return }
        strokes.removeLast()
        rebuildComposite()
        needsDisplay = true
        onStrokesChanged?()
    }

    func currentImage() -> NSImage? {
        rebuildComposite()
        return renderedImage ?? baseImage
    }

    private func commitStroke(from start: CGPoint, to end: CGPoint) {
        if activeTool == .text {
            promptForText(at: end) { [weak self] text in
                guard let self, !text.isEmpty else { return }
                self.strokes.append(AnnotationStroke(
                    tool: .text,
                    start: end,
                    end: end,
                    text: text,
                    color: self.strokeColor,
                    lineWidth: self.lineWidth
                ))
                self.rebuildComposite()
                self.needsDisplay = true
                self.onStrokesChanged?()
            }
            return
        }
        strokes.append(AnnotationStroke(
            tool: activeTool,
            start: start,
            end: end,
            text: "",
            color: strokeColor,
            lineWidth: lineWidth
        ))
        rebuildComposite()
        needsDisplay = true
        onStrokesChanged?()
    }

    private func promptForText(at point: CGPoint, completion: @escaping (String) -> Void) {
        let alert = NSAlert()
        alert.messageText = "Add Text"
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        alert.accessoryView = field
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            completion(field.stringValue)
        }
    }

    func rebuildComposite() {
        guard let baseImage else {
            renderedImage = nil
            return
        }
        let size = baseImage.size
        let image = NSImage(size: size)
        image.lockFocus()
        baseImage.draw(in: NSRect(origin: .zero, size: size))
        let canvas = NSRect(origin: .zero, size: size)
        for region in redactionRegions {
            pixelate(from: CGPoint(x: region.minX, y: region.minY), to: CGPoint(x: region.maxX, y: region.maxY), in: canvas)
        }
        for stroke in strokes {
            drawStroke(stroke, in: canvas)
        }
        image.unlockFocus()
        renderedImage = image
    }

    private func drawStroke(_ stroke: AnnotationStroke, in rect: NSRect) {
        switch stroke.tool {
        case .arrow:
            stroke.color.setStroke()
            let path = NSBezierPath()
            path.move(to: stroke.start)
            path.line(to: stroke.end)
            path.lineWidth = stroke.lineWidth
            path.stroke()
            addArrowHead(to: path, at: stroke.end, from: stroke.start, width: stroke.lineWidth)
        case .rectangle:
            stroke.color.setStroke()
            let box = NSRect(
                x: min(stroke.start.x, stroke.end.x),
                y: min(stroke.start.y, stroke.end.y),
                width: abs(stroke.end.x - stroke.start.x),
                height: abs(stroke.end.y - stroke.start.y)
            )
            let path = NSBezierPath(rect: box)
            path.lineWidth = stroke.lineWidth
            path.stroke()
        case .text:
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: max(16, stroke.lineWidth * 4)),
                .foregroundColor: stroke.color
            ]
            (stroke.text as NSString).draw(at: stroke.start, withAttributes: attributes)
        case .pixelate:
            pixelate(from: stroke.start, to: stroke.end, in: rect)
        case .measure:
            break
        }
    }

    private func addArrowHead(to path: NSBezierPath, at tip: CGPoint, from tail: CGPoint, width: CGFloat) {
        let angle = atan2(tip.y - tail.y, tip.x - tail.x)
        let head = width * 3
        let p1 = CGPoint(
            x: tip.x - head * cos(angle - .pi / 6),
            y: tip.y - head * sin(angle - .pi / 6)
        )
        let p2 = CGPoint(
            x: tip.x - head * cos(angle + .pi / 6),
            y: tip.y - head * sin(angle + .pi / 6)
        )
        path.move(to: tip)
        path.line(to: p1)
        path.move(to: tip)
        path.line(to: p2)
        path.lineWidth = width
        path.stroke()
    }

    private func pixelate(from start: CGPoint, to end: CGPoint, in rect: NSRect) {
        guard let baseImage, let cg = baseImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        let region = NSRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        guard region.width > 2, region.height > 2 else { return }

        let scaleX = CGFloat(cg.width) / rect.width
        let scaleY = CGFloat(cg.height) / rect.height
        let crop = CGRect(
            x: region.origin.x * scaleX,
            y: CGFloat(cg.height) - (region.origin.y + region.height) * scaleY,
            width: region.width * scaleX,
            height: region.height * scaleY
        ).integral
        guard let cropped = cg.cropping(to: crop) else { return }

        let ci = CIImage(cgImage: cropped)
        guard let filter = CIFilter(name: "CIPixellate") else { return }
        filter.setValue(ci, forKey: kCIInputImageKey)
        filter.setValue(12, forKey: kCIInputScaleKey)
        guard let output = filter.outputImage else { return }
        let context = CIContext()
        guard let pix = context.createCGImage(output, from: output.extent) else { return }
        let patch = NSImage(cgImage: pix, size: region.size)
        patch.draw(in: region)
    }
}
