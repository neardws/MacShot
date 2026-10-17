import CoreGraphics
import Foundation

/// Pure layout for the annotation editor window: image-sized canvas plus toolbar chrome.
public enum AnnotationEditorWindowLayout {
    public struct Input: Equatable, Sendable {
        public var imagePixelWidth: CGFloat
        public var imagePixelHeight: CGFloat
        public var backingScaleFactor: CGFloat
        public var visibleFrameWidth: CGFloat
        public var visibleFrameHeight: CGFloat
        public var toolbarHeight: CGFloat
        public var verticalChrome: CGFloat
        public var horizontalChrome: CGFloat
        public var minimumCanvasWidth: CGFloat
        public var minimumCanvasHeight: CGFloat

        public init(
            imagePixelWidth: CGFloat,
            imagePixelHeight: CGFloat,
            backingScaleFactor: CGFloat,
            visibleFrameWidth: CGFloat,
            visibleFrameHeight: CGFloat,
            toolbarHeight: CGFloat,
            verticalChrome: CGFloat,
            horizontalChrome: CGFloat,
            minimumCanvasWidth: CGFloat = 320,
            minimumCanvasHeight: CGFloat = 240
        ) {
            self.imagePixelWidth = imagePixelWidth
            self.imagePixelHeight = imagePixelHeight
            self.backingScaleFactor = max(backingScaleFactor, 1)
            self.visibleFrameWidth = visibleFrameWidth
            self.visibleFrameHeight = visibleFrameHeight
            self.toolbarHeight = toolbarHeight
            self.verticalChrome = verticalChrome
            self.horizontalChrome = horizontalChrome
            self.minimumCanvasWidth = minimumCanvasWidth
            self.minimumCanvasHeight = minimumCanvasHeight
        }
    }

    public struct Result: Equatable, Sendable {
        public var windowContentSize: CGSize
        public var canvasSize: CGSize
        public var imageScale: CGFloat
    }

    /// Converts pixel dimensions to points using the display scale factor.
    public static func imageSizeInPoints(
        pixelWidth: CGFloat,
        pixelHeight: CGFloat,
        backingScaleFactor: CGFloat
    ) -> CGSize {
        let scale = max(backingScaleFactor, 1)
        let w = max(pixelWidth, 1) / scale
        let h = max(pixelHeight, 1) / scale
        return CGSize(width: w, height: h)
    }

    public static func layout(for input: Input) -> Result {
        let imagePoints = imageSizeInPoints(
            pixelWidth: input.imagePixelWidth,
            pixelHeight: input.imagePixelHeight,
            backingScaleFactor: input.backingScaleFactor
        )

        let chromeW = input.horizontalChrome
        let chromeH = input.verticalChrome + input.toolbarHeight

        let maxCanvasW = max(input.visibleFrameWidth - chromeW, input.minimumCanvasWidth)
        let maxCanvasH = max(input.visibleFrameHeight - chromeH, input.minimumCanvasHeight)

        let fitScale = min(
            maxCanvasW / imagePoints.width,
            maxCanvasH / imagePoints.height
        )
        let imageScale = min(1, fitScale)

        var canvasW = floor(imagePoints.width * imageScale)
        var canvasH = floor(imagePoints.height * imageScale)
        canvasW = max(canvasW, input.minimumCanvasWidth)
        canvasH = max(canvasH, input.minimumCanvasHeight)

        // If minimum canvas exceeds visible area, shrink again proportionally.
        if canvasW + chromeW > input.visibleFrameWidth || canvasH + chromeH > input.visibleFrameHeight {
            let shrink = min(
                (input.visibleFrameWidth - chromeW) / canvasW,
                (input.visibleFrameHeight - chromeH) / canvasH
            )
            let clamped = max(shrink, 0.01)
            canvasW = floor(canvasW * clamped)
            canvasH = floor(canvasH * clamped)
        }

        let windowW = canvasW + chromeW
        let windowH = canvasH + chromeH

        return Result(
            windowContentSize: CGSize(width: windowW, height: windowH),
            canvasSize: CGSize(width: canvasW, height: canvasH),
            imageScale: imageScale
        )
    }

    /// Centers a content-sized rect inside a visible desktop frame (AppKit bottom-left origin).
    public static func centeredContentFrame(
        contentSize: CGSize,
        visibleFrame: CGRect
    ) -> CGRect {
        let w = contentSize.width
        let h = contentSize.height
        let x = visibleFrame.midX - w / 2
        let y = visibleFrame.midY - h / 2
        let clampedX = min(max(x, visibleFrame.minX), visibleFrame.maxX - w)
        let clampedY = min(max(y, visibleFrame.minY), visibleFrame.maxY - h)
        return CGRect(x: clampedX, y: clampedY, width: w, height: h)
    }
}
