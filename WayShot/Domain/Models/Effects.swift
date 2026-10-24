import Foundation

public struct Effects: Codable, Equatable {
    public var grain: Float = 0.0    // 0 to 100
    public var dust: Float = 0.0     // 0 to 100
    public var leaks: Float = 0.0    // 0 to 100
    public var glow: Float = 0.0     // 0 to 100
    public var chroma: Float = 0.0   // 0 to 100
    public var vhs: Float = 0.0      // 0 to 100

    public init(
        grain: Float = 0.0,
        dust: Float = 0.0,
        leaks: Float = 0.0,
        glow: Float = 0.0,
        chroma: Float = 0.0,
        vhs: Float = 0.0
    ) {
        self.grain = grain
        self.dust = dust
        self.leaks = leaks
        self.glow = glow
        self.chroma = chroma
        self.vhs = vhs
    }

    public func hasActiveEffects() -> Bool {
        return grain > 0.0 || dust > 0.0 || leaks > 0.0 || glow > 0.0 || chroma > 0.0 || vhs > 0.0
    }
}
