import AppKit
import XCTest
@testable import OctoshotCore

final class ImageFormatsTests: XCTestCase {
    func testCopyToPasteboardUsesPNGType() {
        let image = NSImage(size: NSSize(width: 4, height: 4))
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(x: 0, y: 0, width: 4, height: 4).fill()
        image.unlockFocus()

        ImageFormats.copyToPasteboard(image)
        let data = NSPasteboard.general.data(forType: .png)
        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data?.count ?? 0, 0)
    }
}
