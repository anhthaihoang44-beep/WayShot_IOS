import XCTest
@testable import WayShot

final class ColorMathTests: XCTestCase {

    func testLumaCalculation() {
        // Rec.709 sRGB Luma: 0.2126 * R + 0.7152 * G + 0.0722 * B
        let whiteLuma: Float = 0.2126 * 1.0 + 0.7152 * 1.0 + 0.0722 * 1.0
        XCTAssertEqual(whiteLuma, 1.0, accuracy: 0.001)

        let blackLuma: Float = 0.2126 * 0.0 + 0.7152 * 0.0 + 0.0722 * 0.0
        XCTAssertEqual(blackLuma, 0.0, accuracy: 0.001)
    }

    func testAdjustmentsDefaultCheck() {
        var adj = Adjustments()
        XCTAssertTrue(adj.isDefault())

        adj.warmth = 5.0
        XCTAssertFalse(adj.isDefault())

        adj.warmth = 0.0
        XCTAssertTrue(adj.isDefault())
    }

    func testEffectsActiveCheck() {
        var fx = Effects()
        XCTAssertFalse(fx.hasActiveEffects())

        fx.grain = 10.0
        XCTAssertTrue(fx.hasActiveEffects())

        fx.grain = 0.0
        XCTAssertFalse(fx.hasActiveEffects())
    }
}
