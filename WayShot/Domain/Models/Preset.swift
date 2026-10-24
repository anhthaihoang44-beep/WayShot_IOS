import Foundation

public struct Preset: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let category: String // DigiCam, Film, Vintage, Retro, Y2K, Minimal, etc.
    public let isPro: Bool
    public let defaultIntensity: Float
    public let saturation: Float
    public let contrast: Float
    public let warmth: Float
    public let fade: Float
    public let shadowTint: [Float]      // RGB r, g, b in 0.0...1.0
    public let highlightTint: [Float]   // RGB r, g, b in 0.0...1.0
    public let grain: Float
    public let lutFile: String?

    public init(
        id: String,
        name: String,
        category: String,
        isPro: Bool = false,
        defaultIntensity: Float = 1.0,
        saturation: Float = 0.0,
        contrast: Float = 0.0,
        warmth: Float = 0.0,
        fade: Float = 0.0,
        shadowTint: [Float] = [0.0, 0.0, 0.0],
        highlightTint: [Float] = [0.0, 0.0, 0.0],
        grain: Float = 0.0,
        lutFile: String? = null
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.isPro = isPro
        self.defaultIntensity = defaultIntensity
        self.saturation = saturation
        self.contrast = contrast
        self.warmth = warmth
        self.fade = fade
        self.shadowTint = shadowTint
        self.highlightTint = highlightTint
        self.grain = grain
        self.lutFile = lutFile
    }

    enum CodingKeys: String, CodingKey {
        case id, name, category, isPro, defaultIntensity, saturation, contrast, warmth, fade, shadowTint, highlightTint, grain, lutFile
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(String.self, forKey: .category)
        isPro = try container.decodeIfPresent(Bool.self, forKey: .isPro) ?? false
        defaultIntensity = try container.decodeIfPresent(Float.self, forKey: .defaultIntensity) ?? 1.0
        saturation = try container.decodeIfPresent(Float.self, forKey: .saturation) ?? 0.0
        contrast = try container.decodeIfPresent(Float.self, forKey: .contrast) ?? 0.0
        warmth = try container.decodeIfPresent(Float.self, forKey: .warmth) ?? 0.0
        fade = try container.decodeIfPresent(Float.self, forKey: .fade) ?? 0.0
        shadowTint = try container.decodeIfPresent([Float].self, forKey: .shadowTint) ?? [0.0, 0.0, 0.0]
        highlightTint = try container.decodeIfPresent([Float].self, forKey: .highlightTint) ?? [0.0, 0.0, 0.0]
        grain = try container.decodeIfPresent(Float.self, forKey: .grain) ?? 0.0
        lutFile = try container.decodeIfPresent(String.self, forKey: .lutFile)
    }
}
