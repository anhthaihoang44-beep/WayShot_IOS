import Foundation

public struct Adjustments: Codable, Equatable {
    public var brightness: Float = 0.0   // -100 to +100
    public var contrast: Float = 0.0     // -100 to +100
    public var saturation: Float = 0.0   // -100 to +100
    public var sharpen: Float = 0.0      // 0 to 100
    public var warmth: Float = 0.0       // -100 to +100
    public var highlights: Float = 0.0   // -100 to +100
    public var shadows: Float = 0.0      // -100 to +100

    public init(
        brightness: Float = 0.0,
        contrast: Float = 0.0,
        saturation: Float = 0.0,
        sharpen: Float = 0.0,
        warmth: Float = 0.0,
        highlights: Float = 0.0,
        shadows: Float = 0.0
    ) {
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.sharpen = sharpen
        self.warmth = warmth
        self.highlights = highlights
        self.shadows = shadows
    }

    public func isDefault() -> Bool {
        return brightness == 0.0 && contrast == 0.0 && saturation == 0.0 &&
            sharpen == 0.0 && warmth == 0.0 && highlights == 0.0 && shadows == 0.0
    }
}
