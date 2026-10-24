import Foundation

public enum HslBand: String, Codable, CaseIterable, Identifiable {
    case red = "RED"
    case orange = "ORANGE"
    case yellow = "YELLOW"
    case green = "GREEN"
    case aqua = "AQUA"
    case blue = "BLUE"
    case purple = "PURPLE"
    case magenta = "MAGENTA"

    public var id: String { rawValue }
}

public struct HslChannel: Codable, Equatable {
    public var hue: Float = 0.0        // -180 to +180
    public var saturation: Float = 0.0 // -100 to +100
    public var luminance: Float = 0.0  // -100 to +100

    public init(hue: Float = 0.0, saturation: Float = 0.0, luminance: Float = 0.0) {
        self.hue = hue
        self.saturation = saturation
        self.luminance = luminance
    }
}

public struct HslAdjustment: Codable, Equatable {
    public var bands: [HslBand: HslChannel]

    public init(bands: [HslBand: HslChannel] = HslBand.allCases.reduce(into: [:]) { $0[$1] = HslChannel() }) {
        self.bands = bands
    }

    public func isDefault() -> Bool {
        return bands.values.allSatisfy { $0.hue == 0.0 && $0.saturation == 0.0 && $0.luminance == 0.0 }
    }
}
