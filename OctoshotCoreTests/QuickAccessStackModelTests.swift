import CoreGraphics
import XCTest
@testable import OctoshotCore

final class QuickAccessStackModelTests: XCTestCase {
    private func id(_ n: UInt8) -> QuickAccessStackItemID {
        let uuid = UUID(uuidString: String(format: "00000000-0000-0000-0000-%012x", UInt64(n)))!
        return QuickAccessStackItemID(uuid)
    }

    func testCollapsedPresentationRequiresMultipleItemsAndCollapseState() {
        var stack = QuickAccessCaptureStack(stackCapturesEnabled: true)
        XCTAssertFalse(stack.showsCollapsedStack)

        stack.prepend(id(1))
        XCTAssertFalse(stack.showsCollapsedStack)

        stack.prepend(id(2))
        XCTAssertTrue(stack.showsCollapsedStack)

        stack.expand()
        XCTAssertFalse(stack.showsCollapsedStack)

        stack.collapse()
        XCTAssertTrue(stack.showsCollapsedStack)

        stack.stackCapturesEnabled = false
        XCTAssertFalse(stack.showsCollapsedStack)
    }

    func testExpandIgnoredForSingleItem() {
        var stack = QuickAccessCaptureStack()
        stack.prepend(id(1))
        stack.expand()
        XCTAssertFalse(stack.isExpanded)
    }

    func testDismissItemCollapsesWhenOneRemains() {
        var stack = QuickAccessCaptureStack()
        stack.prepend(id(1))
        stack.prepend(id(2))
        stack.expand()
        XCTAssertTrue(stack.isExpanded)

        XCTAssertFalse(stack.dismissItem(id(2)))
        XCTAssertEqual(stack.count, 1)
        XCTAssertFalse(stack.isExpanded)
    }

    func testDismissLastItemReturnsEmpty() {
        var stack = QuickAccessCaptureStack()
        stack.prepend(id(1))
        XCTAssertTrue(stack.dismissItem(id(1)))
        XCTAssertTrue(stack.itemIDs.isEmpty)
    }

    func testTrimToMaxKeepsNewest() {
        var stack = QuickAccessCaptureStack(maxCount: 2)
        stack.prepend(id(1))
        stack.prepend(id(2))
        stack.prepend(id(3))
        XCTAssertEqual(stack.itemIDs, [id(3), id(2)])
    }

    func testExpandedPanelHeightGrowsWithCardCount() {
        let single = QuickAccessStackPanelLayout.expandedPanelContentHeight(
            cardHeights: [120],
            includesMultiCaptureHeader: false
        )
        let triple = QuickAccessStackPanelLayout.expandedPanelContentHeight(
            cardHeights: [120, 120, 120],
            includesMultiCaptureHeader: true
        )
        XCTAssertGreaterThan(triple, single)
        XCTAssertEqual(
            triple - single,
            120 * 2 + QuickAccessStackPanelLayout.interCardSpacing * 2
                + QuickAccessStackPanelLayout.multiCaptureHeaderHeight
                + QuickAccessStackPanelLayout.interCardSpacing,
            accuracy: 0.5
        )
    }

    func testCollapsedPanelSizeIncludesHeaderAndPadding() {
        let card = CGSize(width: 200, height: 150)
        let size = QuickAccessStackPanelLayout.collapsedPanelContentSize(
            frontCardSize: card,
            total: 3,
            placement: .bottomRight
        )
        let fan = QuickAccessStackGeometry.collapsedStackContentSize(
            frontCardSize: card,
            total: 3,
            placement: .bottomRight
        )
        let expectedHeight = fan.height
            + QuickAccessStackPanelLayout.multiCaptureHeaderHeight
            + QuickAccessStackPanelLayout.interCardSpacing
            + QuickAccessStackPanelLayout.outerPadding * 2
        XCTAssertEqual(size.height, expectedHeight, accuracy: 0.5)
        XCTAssertEqual(size.width, fan.width + QuickAccessStackPanelLayout.outerPadding * 2, accuracy: 0.5)
    }
}
