import AppKit

enum ScrollStitcher {
    /// Vertically stitches scroll frames by trimming overlap (row-diff heuristic).
    static func stitch(frames: [NSImage]) -> NSImage? {
        guard let first = frames.first else { return nil }
        if frames.count == 1 { return first }
        var result = first
        for index in 1..<frames.count {
            guard let merged = appendVertically(top: result, bottom: frames[index]) else { continue }
            result = merged
        }
        return result
    }

    private static func appendVertically(top: NSImage, bottom: NSImage) -> NSImage? {
        guard let topCG = top.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let bottomCG = bottom.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }

        let overlap = estimateOverlap(top: topCG, bottom: bottomCG, searchHeight: min(120, bottomCG.height / 3))
        let trimmedBottomHeight = max(1, bottomCG.height - overlap)
        let newHeight = topCG.height + trimmedBottomHeight
        let pixelWidth = max(topCG.width, bottomCG.width)
        let canvasWidth = CGFloat(pixelWidth)
        let trimmedHeight = CGFloat(trimmedBottomHeight)

        let output = NSImage(size: NSSize(width: canvasWidth, height: CGFloat(newHeight)))
        output.lockFocus()
        top.draw(in: NSRect(x: 0, y: trimmedHeight, width: canvasWidth, height: top.size.height))
        if let slice = bottomCG.cropping(to: CGRect(x: 0, y: 0, width: bottomCG.width, height: trimmedBottomHeight)) {
            NSImage(cgImage: slice, size: NSSize(width: CGFloat(slice.width), height: trimmedHeight))
                .draw(in: NSRect(x: 0, y: 0, width: canvasWidth, height: trimmedHeight))
        }
        output.unlockFocus()
        return output
    }

    private static func estimateOverlap(top: CGImage, bottom: CGImage, searchHeight: Int) -> Int {
        let h = min(searchHeight, top.height, bottom.height)
        guard h > 4 else { return 0 }
        var bestOffset = 0
        var bestScore = Int.max
        for offset in 0..<h {
            let score = rowDifference(
                top: top,
                topYStart: top.height - h + offset,
                bottom: bottom,
                bottomYStart: offset,
                rowCount: h - offset
            )
            if score < bestScore {
                bestScore = score
                bestOffset = offset
            }
        }
        return bestOffset
    }

    private static func rowDifference(top: CGImage, topYStart: Int, bottom: CGImage, bottomYStart: Int, rowCount: Int) -> Int {
        guard let topData = top.dataProvider?.data,
              let bottomData = bottom.dataProvider?.data else { return Int.max }
        let topPtr = CFDataGetBytePtr(topData)
        let bottomPtr = CFDataGetBytePtr(bottomData)
        let topBPR = top.bytesPerRow
        let bottomBPR = bottom.bytesPerRow
        var diff = 0
        let rows = min(rowCount, top.height - topYStart, bottom.height - bottomYStart)
        let samples = min(top.width, bottom.width, 64)
        for row in 0..<rows {
            let ty = topYStart + row
            let by = bottomYStart + row
            for col in stride(from: 0, to: samples, by: 4) {
                let tIdx = ty * topBPR + col * 4
                let bIdx = by * bottomBPR + col * 4
                diff += abs(Int(topPtr![tIdx]) - Int(bottomPtr![bIdx]))
            }
        }
        return diff
    }
}
