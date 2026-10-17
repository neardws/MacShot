import XCTest
@testable import OctoshotCore

final class AnnotationEditorWindowLayoutTests: XCTestCase {
    func testImageSizeInPointsUsesBackingScale() {
        let size = AnnotationEditorWindowLayout.imageSizeInPoints(
            pixelWidth: 2880,
            pixelHeight: 1800,
            backingScaleFactor: 2
        )
        XCTAssertEqual(size.width, 1440, accuracy: 0.01)
        XCTAssertEqual(size.height, 900, accuracy: 0.01)
    }

    func testLayoutFitsImageOnScreenWhenSmall() {
        let input = AnnotationEditorWindowLayout.Input(
            imagePixelWidth: 800,
            imagePixelHeight: 600,
            backingScaleFactor: 1,
            visibleFrameWidth: 1600,
            visibleFrameHeight: 1000,
            toolbarHeight: 52,
            verticalChrome: 28,
            horizontalChrome: 24
        )
        let result = AnnotationEditorWindowLayout.layout(for: input)
        XCTAssertEqual(result.canvasSize.width, 800, accuracy: 1)
        XCTAssertEqual(result.canvasSize.height, 600, accuracy: 1)
        XCTAssertEqual(result.imageScale, 1, accuracy: 0.001)
        XCTAssertEqual(result.windowContentSize.width, 824, accuracy: 1)
        XCTAssertEqual(result.windowContentSize.height, 680, accuracy: 1)
    }

    func testLayoutScalesDownLargeImage() {
        let input = AnnotationEditorWindowLayout.Input(
            imagePixelWidth: 4000,
            imagePixelHeight: 3000,
            backingScaleFactor: 2,
            visibleFrameWidth: 1200,
            visibleFrameHeight: 800,
            toolbarHeight: 52,
            verticalChrome: 28,
            horizontalChrome: 24
        )
        let result = AnnotationEditorWindowLayout.layout(for: input)
        XCTAssertLessThan(result.canvasSize.width, 2000)
        XCTAssertLessThan(result.canvasSize.height, 1500)
        XCTAssertLessThanOrEqual(
            result.windowContentSize.width,
            input.visibleFrameWidth + 0.5
        )
        XCTAssertLessThanOrEqual(
            result.windowContentSize.height,
            input.visibleFrameHeight + 0.5
        )
        let aspect = result.canvasSize.width / result.canvasSize.height
        XCTAssertEqual(aspect, 2000 / 1500, accuracy: 0.02)
    }

    func testCenteredContentFrameIsInsideVisibleFrame() {
        let visible = CGRect(x: 100, y: 50, width: 1200, height: 900)
        let frame = AnnotationEditorWindowLayout.centeredContentFrame(
            contentSize: CGSize(width: 400, height: 300),
            visibleFrame: visible
        )
        XCTAssertTrue(visible.contains(frame))
        XCTAssertEqual(frame.midX, visible.midX, accuracy: 0.5)
        XCTAssertEqual(frame.midY, visible.midY, accuracy: 0.5)
    }
}
