import CoreGraphics
import Foundation

/// Where the post-capture quick-access panel is anchored on a display.
public enum QuickAccessPlacement: String, CaseIterable, Identifiable, Codable, Sendable {
    case bottomLeft
    case bottomRight
    case leftSidebar
    case rightSidebar

    public var id: String { rawValue }

    /// Maps legacy `QuickAccessCorner` raw values saved before sidebar placements existed.
    public static func migrated(fromLegacyRawValue raw: String) -> QuickAccessPlacement {
        if let placement = QuickAccessPlacement(rawValue: raw) {
            return placement
        }
        switch raw {
        case "topLeft":
            return .leftSidebar
        case "topRight":
            return .rightSidebar
        case "bottomLeft":
            return .bottomLeft
        default:
            return .bottomRight
        }
    }

    public var isSidebar: Bool {
        switch self {
        case .leftSidebar, .rightSidebar:
            return true
        case .bottomLeft, .bottomRight:
            return false
        }
    }
}

public struct QuickAccessScreenInfo: Sendable, Equatable {
    public let displayID: UInt32
    public let frame: CGRect
    public let visibleFrame: CGRect

    public init(displayID: UInt32, frame: CGRect, visibleFrame: CGRect) {
        self.displayID = displayID
        self.frame = frame
        self.visibleFrame = visibleFrame
    }
}

public enum QuickAccessScreenSelection {
    /// Picks the screen containing `capturePoint`, else `mousePoint`, else the first screen.
    public static func selectScreen(
        screens: [QuickAccessScreenInfo],
        capturePoint: CGPoint?,
        mousePoint: CGPoint?
    ) -> QuickAccessScreenInfo? {
        guard !screens.isEmpty else { return nil }
        if let point = capturePoint, let match = screens.first(where: { $0.frame.contains(point) }) {
            return match
        }
        if let point = mousePoint, let match = screens.first(where: { $0.frame.contains(point) }) {
            return match
        }
        return screens.first
    }
}

public enum QuickAccessPanelGeometry {
    /// AppKit global origin (bottom-left) for a borderless panel of `panelSize`.
    public static func panelOrigin(
        placement: QuickAccessPlacement,
        visibleFrame: CGRect,
        panelSize: CGSize,
        margin: CGFloat
    ) -> CGPoint {
        let inset = visibleFrame.insetBy(dx: margin, dy: margin)
        let maxX = inset.maxX - panelSize.width
        let maxY = inset.maxY - panelSize.height
        let minX = inset.minX
        let minY = inset.minY

        var origin: CGPoint
        switch placement {
        case .bottomLeft:
            origin = CGPoint(x: minX, y: minY)
        case .bottomRight:
            origin = CGPoint(x: maxX, y: minY)
        case .leftSidebar:
            origin = CGPoint(x: minX, y: maxY)
        case .rightSidebar:
            origin = CGPoint(x: maxX, y: maxY)
        }

        origin.x = min(max(origin.x, minX), maxX)
        origin.y = min(max(origin.y, minY), maxY)
        return origin
    }
}

public enum QuickAccessStackGeometry {
    /// Maximum cards drawn in the collapsed stack peek.
    public static let maxCollapsedLayers = 5

    /// Visual offset for a card at `index` (0 = front / newest) when the stack is collapsed.
    public static func collapsedOffset(index: Int, total: Int, placement: QuickAccessPlacement) -> CGSize {
        guard total > 1, index > 0 else { return .zero }
        let layer = min(index, maxCollapsedLayers)
        let signX: CGFloat = placement == .leftSidebar || placement == .bottomLeft ? 1 : -1
        let signY: CGFloat = placement.isSidebar ? -1 : 1
        return CGSize(width: signX * CGFloat(layer) * 5, height: signY * CGFloat(layer) * 4)
    }

    /// Z-index ordering: front card highest.
    public static func collapsedZIndex(index: Int, total: Int) -> Double {
        Double(total - index)
    }
}
