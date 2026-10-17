import AppKit
import CoreImage

public enum AnnotationRenderer {
    public static func apply(spec: AgentAnnotationSpec, to image: NSImage) -> NSImage {
        let size = image.size
        let output = NSImage(size: size)
        output.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size))
        let canvas = NSRect(origin: .zero, size: size)
        for item in spec.annotations {
            draw(item: item, in: canvas, sourceImage: image)
        }
        output.unlockFocus()
        return output
    }

    private static func draw(item: AgentAnnotationSpec.Item, in canvas: NSRect, sourceImage: NSImage) {
        let color = parseColor(item.color) ?? .systemRed
        let width = CGFloat(item.lineWidth ?? 4)
        switch item.type {
        case .arrow:
            guard let from = item.from, let to = item.to, from.count >= 2, to.count >= 2 else { return }
            let start = CGPoint(x: from[0], y: from[1])
            let end = CGPoint(x: to[0], y: to[1])
            color.setStroke()
            let path = NSBezierPath()
            path.move(to: start)
            path.line(to: end)
            path.lineWidth = width
            path.stroke()
            addArrowHead(to: path, at: end, from: start, width: width)
        case .line:
            guard let from = item.from, let to = item.to, from.count >= 2, to.count >= 2 else { return }
            color.setStroke()
            let path = NSBezierPath()
            path.move(to: CGPoint(x: from[0], y: from[1]))
            path.line(to: CGPoint(x: to[0], y: to[1]))
            path.lineWidth = width
            path.stroke()
        case .rectangle:
            guard let from = item.from, let to = item.to, from.count >= 2, to.count >= 2 else { return }
            let rect = rect(from: from, to: to)
            color.setStroke()
            let path = NSBezierPath(rect: rect)
            path.lineWidth = width
            path.stroke()
        case .ellipse:
            guard let from = item.from, let to = item.to, from.count >= 2, to.count >= 2 else { return }
            let path = NSBezierPath(ovalIn: rect(from: from, to: to))
            color.setStroke()
            path.lineWidth = width
            path.stroke()
        case .pen, .highlighter:
            guard let points = item.points, points.count >= 4 else { return }
            var cgPoints: [CGPoint] = []
            var index = 0
            while index + 1 < points.count {
                cgPoints.append(CGPoint(x: points[index], y: points[index + 1]))
                index += 2
            }
            guard let first = cgPoints.first else { return }
            let path = NSBezierPath()
            path.move(to: first)
            for point in cgPoints.dropFirst() {
                path.line(to: point)
            }
            if item.type == .highlighter {
                color.withAlphaComponent(0.35).setStroke()
                path.lineWidth = max(width * 3, 12)
            } else {
                color.setStroke()
                path.lineWidth = width
            }
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.stroke()
        case .text:
            guard let at = item.at, at.count >= 2, let text = item.text else { return }
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: max(16, width * 4)),
                .foregroundColor: color
            ]
            (text as NSString).draw(at: CGPoint(x: at[0], y: at[1]), withAttributes: attributes)
        case .counter:
            guard let at = item.at, at.count >= 2 else { return }
            let center = CGPoint(x: at[0], y: at[1])
            let value = item.counter ?? 1
            let diameter = max(28, width * 8)
            let circle = NSBezierPath(ovalIn: CGRect(
                x: center.x - diameter / 2,
                y: center.y - diameter / 2,
                width: diameter,
                height: diameter
            ))
            color.setFill()
            circle.fill()
            NSColor.white.setStroke()
            circle.lineWidth = 1.5
            circle.stroke()
            let label = "\(value)" as NSString
            let font = NSFont.boldSystemFont(ofSize: diameter * 0.45)
            let size = label.size(withAttributes: [.font: font])
            let origin = NSPoint(x: center.x - size.width / 2, y: center.y - size.height / 2)
            label.draw(at: origin, withAttributes: [.font: font, .foregroundColor: NSColor.white])
        case .pixelate:
            guard let from = item.from, let to = item.to, from.count >= 2, to.count >= 2 else { return }
            let region = rect(from: from, to: to)
            drawPixelate(in: region, source: canvas, sourceImage: sourceImage)
        case .blur:
            guard let from = item.from, let to = item.to, from.count >= 2, to.count >= 2 else { return }
            let region = rect(from: from, to: to)
            drawBlur(in: region, source: canvas, sourceImage: sourceImage)
        }
    }

    private static func rect(from: [Double], to: [Double]) -> NSRect {
        NSRect(
            x: min(from[0], to[0]),
            y: min(from[1], to[1]),
            width: abs(to[0] - from[0]),
            height: abs(to[1] - from[1])
        )
    }

    private static func parseColor(_ hex: String?) -> NSColor? {
        guard var raw = hex?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        if raw.hasPrefix("#") { raw.removeFirst() }
        guard raw.count == 6, let value = UInt64(raw, radix: 16) else { return nil }
        let r = CGFloat((value >> 16) & 0xFF) / 255
        let g = CGFloat((value >> 8) & 0xFF) / 255
        let b = CGFloat(value & 0xFF) / 255
        return NSColor(red: r, green: g, blue: b, alpha: 1)
    }

    private static func addArrowHead(to path: NSBezierPath, at tip: CGPoint, from tail: CGPoint, width: CGFloat) {
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

    private static func drawPixelate(in region: NSRect, source: NSRect, sourceImage: NSImage) {
        guard let cg = sourceImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        guard region.width > 2, region.height > 2 else { return }
        let scaleX = CGFloat(cg.width) / source.width
        let scaleY = CGFloat(cg.height) / source.height
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
        NSImage(cgImage: pix, size: region.size).draw(in: region)
    }

    private static func drawBlur(in region: NSRect, source: NSRect, sourceImage: NSImage) {
        guard let cg = sourceImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        guard region.width > 2, region.height > 2 else { return }
        let scaleX = CGFloat(cg.width) / source.width
        let scaleY = CGFloat(cg.height) / source.height
        let crop = CGRect(
            x: region.origin.x * scaleX,
            y: CGFloat(cg.height) - (region.origin.y + region.height) * scaleY,
            width: region.width * scaleX,
            height: region.height * scaleY
        ).integral
        guard let cropped = cg.cropping(to: crop) else { return }
        let ci = CIImage(cgImage: cropped)
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return }
        filter.setValue(ci, forKey: kCIInputImageKey)
        filter.setValue(14, forKey: kCIInputRadiusKey)
        guard let output = filter.outputImage else { return }
        let context = CIContext()
        guard let blurred = context.createCGImage(output, from: output.extent) else { return }
        NSImage(cgImage: blurred, size: region.size).draw(in: region)
    }
}
