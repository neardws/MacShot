import CoreGraphics
import Foundation

public struct AgentDisplayInfo: Codable, Sendable {
    public let displayID: UInt32
    public let width: Int
    public let height: Int
    public let isMain: Bool
}

public struct AgentWindowInfo: Codable, Sendable {
    public let windowID: UInt32
    public let title: String
    public let appName: String
    public let frame: AgentRect
}

public struct AgentRect: Codable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(_ rect: CGRect) {
        x = rect.origin.x
        y = rect.origin.y
        width = rect.size.width
        height = rect.size.height
    }
}

public struct AgentCaptureResult: Codable, Sendable {
    public let path: String?
    public let base64PNG: String?
    public let width: Double
    public let height: Double
    public let mode: String
    public let displayID: UInt32?
    public let windowID: UInt32?
    public let windowTitle: String?
    public let appName: String?
}

public struct AgentOCRResult: Codable, Sendable {
    public let text: String
    public let lines: [String]
}

public struct AgentAnnotationSpec: Codable, Sendable {
    public struct Item: Codable, Sendable {
        public enum Kind: String, Codable, Sendable {
            case arrow, rectangle, text, pixelate
        }
        public var type: Kind
        public var from: [Double]?
        public var to: [Double]?
        public var at: [Double]?
        public var text: String?
        public var color: String?
        public var lineWidth: Double?
    }
    public var annotations: [Item]
}
