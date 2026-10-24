import Foundation

public enum AspectRatio: String, Codable, CaseIterable, Identifiable {
    case original = "Original"
    case ratio1_1 = "1:1"
    case ratio4_5 = "4:5"
    case ratio3_4 = "3:4"
    case ratio9_16 = "9:16"
    case ratio16_9 = "16:9"
    case ratioFacebook = "1.91:1"

    public var id: String { rawValue }

    public var label: String { rawValue }

    public var ratio: Float? {
        switch self {
        case .original: return nil
        case .ratio1_1: return 1.0
        case .ratio4_5: return 4.0 / 5.0
        case .ratio3_4: return 3.0 / 4.0
        case .ratio9_16: return 9.0 / 16.0
        case .ratio16_9: return 16.0 / 9.0
        case .ratioFacebook: return 1.91
        }
    }
}

public enum BorderType: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case polaroid = "Polaroid"
    case filmStrip = "Film Strip"
    case minimalWhite = "White Frame"
    case minimalBlack = "Black Frame"

    public var id: String { rawValue }
    public var label: String { rawValue }
}

public struct Border: Codable, Equatable {
    public var type: BorderType = .none
    public var widthPercent: Float = 0.05 // 0.02 to 0.15

    public init(type: BorderType = .none, widthPercent: Float = 0.05) {
        self.type = type
        self.widthPercent = widthPercent
    }
}

public struct CropTransform: Codable, Equatable {
    public var aspectRatio: AspectRatio = .original
    public var rotationDegrees: Int = 0 // 0, 90, 180, 270
    public var flipHorizontal: Bool = false
    public var flipVertical: Bool = false

    public init(
        aspectRatio: AspectRatio = .original,
        rotationDegrees: Int = 0,
        flipHorizontal: Bool = false,
        flipVertical: Bool = false
    ) {
        self.aspectRatio = aspectRatio
        self.rotationDegrees = rotationDegrees
        self.flipHorizontal = flipHorizontal
        self.flipVertical = flipVertical
    }

    public func isDefault() -> Bool {
        return aspectRatio == .original && rotationDegrees == 0 &&
            !flipHorizontal && !flipVertical
    }
}
