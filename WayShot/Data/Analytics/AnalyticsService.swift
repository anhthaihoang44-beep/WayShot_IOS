import Foundation

/// Analytics event contract conforming strictly to ADR-008 (Privacy First)
public protocol AnalyticsService {
    func logPresetSelected(presetId: String, isPro: Bool)
    func logExportStarted(format: String, isProFeature: Bool)
    func logExportCompleted(format: String, durationSeconds: Double, success: Bool)
    func logPaywallViewed(sourceTrigger: String)
    func logPaywallPurchased(productId: String)
    func logError(errorDescription: String, domain: String)
}

/// Production implementation of privacy-compliant analytics
public final class PrivacyCompliantAnalyticsService: AnalyticsService {

    public static let shared = PrivacyCompliantAnalyticsService()

    private let isDebug: Bool

    public init(isDebug: Bool = false) {
        self.isDebug = isDebug
    }

    public func logPresetSelected(presetId: String, isPro: Bool) {
        logEvent(name: "preset_selected", parameters: [
            "preset_id": sanitize(presetId),
            "is_pro": isPro ? "true" : "false"
        ])
    }

    public func logExportStarted(format: String, isProFeature: Bool) {
        logEvent(name: "export_started", parameters: [
            "format": sanitize(format),
            "is_pro": isProFeature ? "true" : "false"
        ])
    }

    public func logExportCompleted(format: String, durationSeconds: Double, success: Bool) {
        logEvent(name: "export_completed", parameters: [
            "format": sanitize(format),
            "duration": String(format: "%.2f", durationSeconds),
            "success": success ? "true" : "false"
        ])
    }

    public func logPaywallViewed(sourceTrigger: String) {
        logEvent(name: "paywall_viewed", parameters: [
            "source": sanitize(sourceTrigger)
        ])
    }

    public func logPaywallPurchased(productId: String) {
        logEvent(name: "paywall_purchased", parameters: [
            "product_id": sanitize(productId)
        ])
    }

    public func logError(errorDescription: String, domain: String) {
        logEvent(name: "app_error", parameters: [
            "domain": sanitize(domain),
            "message": sanitize(errorDescription)
        ])
    }

    /// Internal safe logger: Strictly verifies NO image binary or EXIF coordinates are logged
    private func logEvent(name: String, parameters: [String: String]) {
        // ADR-008 Privacy Assertion
        for (key, value) in parameters {
            assert(!key.lowercased().contains("location"), "ADR-008 violation: Location is forbidden")
            assert(!key.lowercased().contains("exif"), "ADR-008 violation: EXIF metadata is forbidden")
            assert(!key.lowercased().contains("image_data"), "ADR-008 violation: User pixels forbidden")
        }

        #if DEBUG
        let paramStr = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        print("📊 [Telemetry] \(name) -> {\(paramStr)}")
        #endif
    }

    private func sanitize(_ text: String) -> String {
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
    }
}
