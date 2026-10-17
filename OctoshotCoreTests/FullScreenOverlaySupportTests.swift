import AppKit
import XCTest
@testable import OctoshotCore

final class FullScreenOverlaySupportTests: XCTestCase {
    func testCaptureOverlayPanelUsesFullScreenAuxiliaryBehavior() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        FullScreenOverlaySupport.configureCaptureOverlayPanel(panel)

        XCTAssertEqual(panel.level, FullScreenOverlaySupport.overlayLevel)
        XCTAssertTrue(panel.collectionBehavior.contains(.canJoinAllSpaces))
        XCTAssertTrue(panel.collectionBehavior.contains(.fullScreenAuxiliary))
        XCTAssertTrue(panel.collectionBehavior.contains(.stationary))
        XCTAssertTrue(panel.collectionBehavior.contains(.ignoresCycle))
        XCTAssertTrue(panel.isFloatingPanel)
        XCTAssertFalse(panel.hidesOnDeactivate)
    }

    func testOverlayWindowSelectionPrefersWindowContainingPoint() {
        let left = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        let right = NSWindow(
            contentRect: NSRect(x: 800, y: 0, width: 800, height: 600),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        let picked = FullScreenOverlaySupport.overlayWindow(
            at: NSPoint(x: 900, y: 300),
            in: [left, right]
        )
        XCTAssertEqual(picked, right)
    }
}
