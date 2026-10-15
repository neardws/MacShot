import AppKit

public enum AnnotationRenderer {
    public static func apply(spec: AgentAnnotationSpec, to image: NSImage) -> NSImage {
        let size = image.size
        let output = NSImage(size: size)
        output.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size))
        for item in spec.annotations {
            draw(item: item, in: NSRect(origin: .zero, size: size))
        }
        output.unlockFocus()
        return output
    }

    private static func draw(item: AgentAnnotationSpec.Item, in canvas: NSRect) {
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
        case .rectangle, .pixelate:
            guard let from = item.from, let to = item.to, from.count >= 2, to.count >= 2 else { return }
            let rect = NSRect(
                x: min(from[0], to[0]),
                y: min(from[1], to[1]),
                width: abs(to[0] - from[0]),
                height: abs(to[1] - from[1])
            )
            if item.type == .rectangle {
                color.setStroke()
                let path = NSBezierPath(rect: rect)
                path.lineWidth = width
                path.stroke()
            } else {
                drawPixelate(in: rect, source: canvas)
            }
        case .text:
            guard let at = item.at, at.count >= 2, let text = item.text else { return }
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: max(16, width * 4)),
                .foregroundColor: color
            ]
            (text as NSString).draw(at: CGPoint(x: at[0], y: at[1]), withAttributes: attributes)
        }
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

    private static func drawPixelate(in region: NSRect, source: NSRect) {
        guard let rep = NSBitmapImageRep(focusedViewRect: region) else { return }
        let block = 12
        for y in stride(from: 0, to: Int(region.height), by: block) {
            for x in stride(from: 0, to: Int(region.width), by: block) {
                let color = rep.colorAt(x: min(x, Int(region.width) - 1), y: min(y, Int(region.height) - 1)) ?? .gray
                color.setFill()
                NSRect(x: region.origin.x + CGFloat(x), y: region.origin.y + CGFloat(y), width: CGFloat(block), height: CGFloat(block)).fill()
            }
        }
    }
}
