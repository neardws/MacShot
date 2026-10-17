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

    private let card = CGSize(width: 200, height: 150)

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

    func testPanelOriginBottomLeft() {
        let size = CGSize(width: 160, height: 100)
        let origin = QuickAccessPanelGeometry.panelOrigin(
            placement: .bottomLeft,
            visibleFrame: primary.visibleFrame,
            panelSize: size,
            margin: 16
        )
        XCTAssertEqual(origin.x, 16, accuracy: 0.5)
        XCTAssertEqual(origin.y, 16, accuracy: 0.5)
    }

    func testClampedPanelOriginKeepsPanelOnScreen() {
        let size = CGSize(width: 400, height: 300)
        let proposed = CGPoint(x: -50, y: -20)
        let clamped = QuickAccessPanelGeometry.clampedPanelOrigin(
            proposedOrigin: proposed,
            visibleFrame: primary.visibleFrame,
            panelSize: size,
            margin: 16
        )
        XCTAssertEqual(clamped.x, 16, accuracy: 0.5)
        XCTAssertEqual(clamped.y, 16, accuracy: 0.5)
    }

    func testLegacyCornerMigration() {
        XCTAssertEqual(QuickAccessPlacement.migrated(fromLegacyRawValue: "topLeft"), .leftSidebar)
        XCTAssertEqual(QuickAccessPlacement.migrated(fromLegacyRawValue: "topRight"), .rightSidebar)
        XCTAssertEqual(QuickAccessPlacement.migrated(fromLegacyRawValue: "bottomRight"), .bottomRight)
        XCTAssertEqual(QuickAccessPlacement.migrated(fromLegacyRawValue: "unknown"), .bottomRight)
    }

    func testCollapsedStackBottomRightFansLeftAndUp() {
        let offset = QuickAccessStackGeometry.collapsedOffset(index: 1, total: 3, placement: .bottomRight)
        XCTAssertLessThan(offset.width, 0)
        XCTAssertLessThan(offset.height, 0)
    }

    func testCollapsedStackBottomLeftFansRightAndUp() {
        let offset = QuickAccessStackGeometry.collapsedOffset(index: 1, total: 3, placement: .bottomLeft)
        XCTAssertGreaterThan(offset.width, 0)
        XCTAssertLessThan(offset.height, 0)
    }

    func testCollapsedStackSidebarFansIntoDisplay() {
        let left = QuickAccessStackGeometry.collapsedOffset(index: 1, total: 3, placement: .leftSidebar)
        XCTAssertGreaterThan(left.width, 0)
        XCTAssertGreaterThan(left.height, 0)

        let right = QuickAccessStackGeometry.collapsedOffset(index: 1, total: 3, placement: .rightSidebar)
        XCTAssertLessThan(right.width, 0)
        XCTAssertGreaterThan(right.height, 0)
    }

    func testCollapsedStackOffsetsIncreaseWithDepth() {
        let first = QuickAccessStackGeometry.collapsedOffset(index: 1, total: 4, placement: .bottomRight)
        let second = QuickAccessStackGeometry.collapsedOffset(index: 2, total: 4, placement: .bottomRight)
        XCTAssertGreaterThan(abs(second.width), abs(first.width))
        XCTAssertGreaterThan(abs(second.height), abs(first.height))
    }

    func testCollapsedStackContentSizeGrowsWithStackDepth() {
        let single = QuickAccessStackGeometry.collapsedStackContentSize(
            frontCardSize: card,
            total: 1,
            placement: .bottomRight
        )
        XCTAssertEqual(single, card)

        let triple = QuickAccessStackGeometry.collapsedStackContentSize(
            frontCardSize: card,
            total: 3,
            placement: .bottomRight
        )
        XCTAssertGreaterThan(triple.width, card.width)
        XCTAssertGreaterThan(triple.height, card.height)
    }

    func testCollapsedStackAnchorMatchesPlacement() {
        XCTAssertEqual(
            QuickAccessStackGeometry.collapsedStackAnchor(placement: .bottomRight),
            .bottomTrailing
        )
        XCTAssertEqual(
            QuickAccessStackGeometry.collapsedStackAnchor(placement: .leftSidebar),
            .topLeading
        )
    }

    func testCollapsedZIndexFrontIsHighest() {
        let total = 4
        XCTAssertGreaterThan(
            QuickAccessStackGeometry.collapsedZIndex(index: 0, total: total),
            QuickAccessStackGeometry.collapsedZIndex(index: 2, total: total)
        )
    }

    func testDragOutcomeRemovesOnlyOnSuccessfulDrop() {
        XCTAssertEqual(QuickAccessDragOutcome.fromEndedDragOperation(0), .keep)
        XCTAssertEqual(QuickAccessDragOutcome.fromEndedDragOperation(1), .removeFromStack)
    }
}
