import CoreGraphics
import XCTest
@testable import OctoshotCore

final class QuickAccessLayoutTests: XCTestCase {
    private let primary = QuickAccessScreenInfo(
        displayID: 1,
        frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
        visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1050)
    )

    private let secondary = QuickAccessScreenInfo(
        displayID: 2,
        frame: CGRect(x: 1920, y: 0, width: 1920, height: 1080),
        visibleFrame: CGRect(x: 1920, y: 0, width: 1920, height: 1050)
    )

    func testScreenSelectionPrefersCapturePoint() {
        let point = CGPoint(x: 2000, y: 500)
        let picked = QuickAccessScreenSelection.selectScreen(
            screens: [primary, secondary],
            capturePoint: point,
            mousePoint: CGPoint(x: 100, y: 100)
        )
        XCTAssertEqual(picked?.displayID, 2)
    }

    func testScreenSelectionFallsBackToMouse() {
        let picked = QuickAccessScreenSelection.selectScreen(
            screens: [primary, secondary],
            capturePoint: nil,
            mousePoint: CGPoint(x: 100, y: 100)
        )
        XCTAssertEqual(picked?.displayID, 1)
    }

    func testPanelOriginBottomRightUsesVisibleFrame() {
        let size = CGSize(width: 200, height: 120)
        let origin = QuickAccessPanelGeometry.panelOrigin(
            placement: .bottomRight,
            visibleFrame: primary.visibleFrame,
            panelSize: size,
            margin: 16
        )
        XCTAssertEqual(origin.x, 1920 - 16 - 200, accuracy: 0.5)
        XCTAssertEqual(origin.y, 16, accuracy: 0.5)
    }

    func testPanelOriginLeftSidebarTopAligned() {
        let size = CGSize(width: 180, height: 400)
        let origin = QuickAccessPanelGeometry.panelOrigin(
            placement: .leftSidebar,
            visibleFrame: primary.visibleFrame,
            panelSize: size,
            margin: 16
        )
        XCTAssertEqual(origin.x, 16, accuracy: 0.5)
        XCTAssertEqual(origin.y, 1050 - 16 - 400, accuracy: 0.5)
    }

    func testLegacyCornerMigration() {
        XCTAssertEqual(QuickAccessPlacement.migrated(fromLegacyRawValue: "topLeft"), .leftSidebar)
        XCTAssertEqual(QuickAccessPlacement.migrated(fromLegacyRawValue: "topRight"), .rightSidebar)
        XCTAssertEqual(QuickAccessPlacement.migrated(fromLegacyRawValue: "bottomRight"), .bottomRight)
        XCTAssertEqual(QuickAccessPlacement.migrated(fromLegacyRawValue: "unknown"), .bottomRight)
    }

    func testCollapsedStackOffsetsIncreaseWithDepth() {
        let first = QuickAccessStackGeometry.collapsedOffset(index: 1, total: 3, placement: .bottomRight)
        let second = QuickAccessStackGeometry.collapsedOffset(index: 2, total: 3, placement: .bottomRight)
        XCTAssertGreaterThan(abs(first.width), 0)
        XCTAssertGreaterThan(abs(second.width), abs(first.width))
    }
}
