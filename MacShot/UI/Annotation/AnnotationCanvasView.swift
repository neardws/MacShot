import AppKit
import CoreImage

final class AnnotationCanvasView: NSView {
    var baseImage: NSImage? {
        didSet { rebuildComposite(); needsDisplay = true }
    }

    var strokes: [AnnotationStroke] = [] {
        didSet { rebuildComposite(); needsDisplay = true }
    }

    var activeTool: AnnotationTool = .arrow
    var strokeColor: NSColor = .systemRed
    var lineWidth: CGFloat = 4

    private var dragStart: CGPoint?
    private var inProgress: AnnotationStroke?
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
    }

    override func mouseDown(with event: NSEvent) {
        dragStart = convert(event.locationInWindow, from: nil)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStart else { return }
        let current = convert(event.locationInWindow, from: nil)
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
        guard let start = dragStart else { return }
        let end = convert(event.locationInWindow, from: nil)
        dragStart = nil
        inProgress = nil
        commitStroke(from: start, to: end)
    }

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
        for stroke in strokes {
            drawStroke(stroke, in: NSRect(origin: .zero, size: size))
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
