import XCTest
@testable import WayShot

final class ADRArchitectureTests: XCTestCase {

    // MARK: - ADR-003: Non-Destructive Pipeline
    func testNonDestructiveInitialState() {
        let session = EditSession()
        XCTAssertEqual(session.currentState.adjustments.brightness, 0.0)
        XCTAssertEqual(session.currentState.presetIntensity, 1.0)
        XCTAssertTrue(session.currentState.curves.isLinear())
        XCTAssertTrue(session.currentState.hsl.isDefault())
    }

    // MARK: - ADR-005 & ADR-006: Shared Preset Format & CDN SHA-256
    func testPresetRepositoryFallbackAndManifest() async throws {
        let repo = PresetRepositoryImpl()
        let presets = try await repo.getPresets()

        XCTAssertFalse(presets.isEmpty)
        XCTAssertTrue(presets.contains { $0.id == "digicam_01" })
        XCTAssertTrue(presets.contains { $0.id == "portra_01" })

        // Check Pro presets
        let proPresets = presets.filter { $0.isPro }
        XCTAssertFalse(proPresets.isEmpty)
        XCTAssertTrue(proPresets.contains { $0.id == "flash_01" || $0.id == "cyber_01" })

        // Test SHA-256 computation
        let testData = "WayShot_Aesthetic_ADR_006".data(using: .utf8)!
        let hash = PresetRepositoryImpl.computeSHA256(data: testData)
        XCTAssertEqual(hash.count, 64)
    }

    // MARK: - ADR-007: Pro Subscription Manager
    @MainActor
    func testProSubscriptionManagerDebugStatus() {
        let manager = ProSubscriptionManager.shared
        manager.setDebugProStatus(true)
        XCTAssertTrue(manager.isPro)

        manager.setDebugProStatus(false)
        XCTAssertFalse(manager.isPro)
    }

    // MARK: - ADR-008: Privacy-Compliant Telemetry
    func testPrivacyCompliantTelemetry() {
        let service = PrivacyCompliantAnalyticsService(isDebug: true)
        // Verify normal events do not trigger assertions or crashes
        service.logPresetSelected(presetId: "portra_01", isPro: false)
        service.logExportStarted(format: "JPEG", isProFeature: true)
        service.logExportCompleted(format: "JPEG", durationSeconds: 0.45, success: true)
        service.logPaywallViewed(sourceTrigger: "preset_card")
        service.logPaywallPurchased(productId: "com.wayshot.pro.yearly")
    }

    // MARK: - ADR-009: Memory & Downsampling Strategy
    func testDownsamplingLogic() {
        let original = SampleImageGenerator.generateAestheticSampleImage(width: 2400, height: 3000)
        let downsampled = ImageIOHelper.downsample(image: original, maxDimension: 1440)

        let maxSide = max(downsampled.size.width, downsampled.size.height)
        XCTAssertLessThanOrEqual(maxSide, 1440.0)
    }

    // MARK: - Curves & HSL Math
    func testCurveEvaluation() {
        let linearPoints = [CurvePoint(x: 0, y: 0), CurvePoint(x: 1, y: 1)]
        let evalMid = WayShotCoreImagePipeline.evaluateCurve(points: linearPoints, value: 0.5)
        XCTAssertEqual(evalMid, 0.5, accuracy: 0.001)

        let sCurve = [
            CurvePoint(x: 0, y: 0),
            CurvePoint(x: 0.5, y: 0.4),
            CurvePoint(x: 1, y: 1)
        ]
        let evalSCurve = WayShotCoreImagePipeline.evaluateCurve(points: sCurve, value: 0.5)
        XCTAssertEqual(evalSCurve, 0.4, accuracy: 0.001)
    }

    func testHslConversionCycle() {
        let (h, s, l) = WayShotCoreImagePipeline.rgbToHsl(r: 1.0, g: 0.0, b: 0.0)
        XCTAssertEqual(h, 0.0, accuracy: 1.0)
        XCTAssertEqual(s, 1.0, accuracy: 0.01)
        XCTAssertEqual(l, 0.5, accuracy: 0.01)

        let band = WayShotCoreImagePipeline.bandForHue(h)
        XCTAssertEqual(band, .red)

        let (r, g, b) = WayShotCoreImagePipeline.hslToRgb(h: h, s: s, l: l)
        XCTAssertEqual(r, 1.0, accuracy: 0.01)
        XCTAssertEqual(g, 0.0, accuracy: 0.01)
        XCTAssertEqual(b, 0.0, accuracy: 0.01)
    }
}
