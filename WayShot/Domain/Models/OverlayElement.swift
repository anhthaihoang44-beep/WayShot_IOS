import Foundation

public protocol OverlayElement: Codable {
    var id: String { get }
    var xNormalized: Float { get set }
    var yNormalized: Float { get set }
    var scale: Float { get set }
    var rotationDegrees: Float { get set }
    var zIndex: Int { get set }
}

public struct TextOverlay: OverlayElement, Codable, Equatable {
    public var id: String
    public var xNormalized: Float = 0.5
    public var yNormalized: Float = 0.5
    public var scale: Float = 1.0
    public var rotationDegrees: Float = 0.0
    public var zIndex: Int = 0
    public var text: String
    public var fontName: String = "Inter"
    public var colorHex: String = "#FFFFFF"
    public var fontSizePoints: Float = 24.0

    public init(
        id: String = UUID().uuidString,
        xNormalized: Float = 0.5,
        yNormalized: Float = 0.5,
        scale: Float = 1.0,
        rotationDegrees: Float = 0.0,
        zIndex: Int = 0,
        text: String,
        fontName: String = "Inter",
        colorHex: String = "#FFFFFF",
        fontSizePoints: Float = 24.0
    ) {
        self.id = id
        self.xNormalized = xNormalized
        self.yNormalized = yNormalized
        self.scale = scale
        self.rotationDegrees = rotationDegrees
        self.zIndex = zIndex
        self.text = text
        self.fontName = fontName
        self.colorHex = colorHex
        self.fontSizePoints = fontSizePoints
    }
}

public struct StickerOverlay: OverlayElement, Codable, Equatable {
    public var id: String
    public var xNormalized: Float = 0.5
    public var yNormalized: Float = 0.5
    public var scale: Float = 1.0
    public var rotationDegrees: Float = 0.0
    public var zIndex: Int = 0
    public var stickerAssetPath: String

    public init(
        id: String = UUID().uuidString,
        xNormalized: Float = 0.5,
        yNormalized: Float = 0.5,
        scale: Float = 1.0,
        rotationDegrees: Float = 0.0,
        zIndex: Int = 0,
        stickerAssetPath: String
    ) {
        self.id = id
        self.xNormalized = xNormalized
        self.yNormalized = yNormalized
        self.scale = scale
        self.rotationDegrees = rotationDegrees
        self.zIndex = zIndex
        self.stickerAssetPath = stickerAssetPath
    }
}
