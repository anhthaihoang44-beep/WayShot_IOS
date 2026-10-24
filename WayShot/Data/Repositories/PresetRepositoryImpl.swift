import Foundation
import CryptoKit

public final class PresetRepositoryImpl: PresetRepository {

    private let fileManager = FileManager.default
    private let cacheFileName = "wayshot_presets_cache.json"

    private var cacheFileURL: URL {
        let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return cachesDir.appendingPathComponent(cacheFileName)
    }

    public init() {}

    /// Retrieves presets following the ADR-006 three-tier fallback:
    /// Tier 1: Local Disk Cache (if exists & valid)
    /// Tier 2: Bundled Starter Kit (`presets_manifest.json`)
    /// Tier 3: In-Memory Default Safe Fallback
    public func getPresets() async throws -> [Preset] {
        // 1. Try disk cache first
        if fileManager.fileExists(atPath: cacheFileURL.path),
           let cachedData = try? Data(contentsOf: cacheFileURL),
           let cachedPresets = try? JSONDecoder().decode([Preset].self, from: cachedData),
           !cachedPresets.isEmpty {
            return cachedPresets
        }

        // 2. Fallback to App Bundle Starter Kit
        if let bundleURL = Bundle.main.url(forResource: "presets_manifest", withExtension: "json", subdirectory: "Presets") ??
                           Bundle.main.url(forResource: "presets_manifest", withExtension: "json"),
           let bundleData = try? Data(contentsOf: bundleURL),
           let bundlePresets = try? JSONDecoder().decode([Preset].self, from: bundleData),
           !bundlePresets.isEmpty {
            return bundlePresets
        }

        // 3. Fallback to built-in code defaults
        return defaultBuiltinPresets()
    }

    /// Synchronizes new presets from remote CDN with SHA-256 checksum verification (ADR-006)
    public func syncFromRemoteCDN(
        manifestURL: URL,
        expectedSha256: String? = nil
    ) async throws -> [Preset] {
        let (data, response) = try await URLSession.shared.data(from: manifestURL)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // Verify SHA-256 integrity if checksum is provided
        if let expected = expectedSha256?.lowercased() {
            let actualHash = SHA256.hash(data: data)
                .compactMap { String(format: "%02x", $0) }
                .joined()

            guard actualHash == expected else {
                throw NSError(
                    domain: "WayShotCDN",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "SHA-256 checksum mismatch for remote preset manifest."]
                )
            }
        }

        // Validate JSON schema
        let remotePresets = try JSONDecoder().decode([Preset].self, from: data)

        // Write to local disk cache atomically
        try data.write(to: cacheFileURL, options: .atomic)

        return remotePresets
    }

    /// Verifies the SHA-256 of any local data or file
    public static func computeSHA256(data: Data) -> String {
        return SHA256.hash(data: data)
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }

    private func defaultBuiltinPresets() -> [Preset] {
        return [
            Preset(
                id: "digicam_01",
                name: "DIGI-CAM 2000",
                category: "DigiCam",
                isPro: false,
                defaultIntensity: 0.9,
                saturation: 14.0,
                contrast: 18.0,
                warmth: 8.0,
                fade: 0.04,
                shadowTint: [0.04, 0.02, 0.06],
                highlightTint: [0.10, 0.08, 0.05],
                grain: 12.0
            ),
            Preset(
                id: "portra_01",
                name: "PORTRA 400",
                category: "Film",
                isPro: false,
                defaultIntensity: 0.95,
                saturation: 8.0,
                contrast: 10.0,
                warmth: 12.0,
                fade: 0.06,
                shadowTint: [0.03, 0.04, 0.05],
                highlightTint: [0.08, 0.06, 0.03],
                grain: 24.0
            ),
            Preset(
                id: "dispo_01",
                name: "DISPO 35mm",
                category: "Vintage",
                isPro: false,
                defaultIntensity: 0.88,
                saturation: 18.0,
                contrast: 22.0,
                warmth: 20.0,
                fade: 0.08,
                shadowTint: [0.06, 0.03, 0.08],
                highlightTint: [0.14, 0.10, 0.04],
                grain: 32.0
            ),
            Preset(
                id: "flash_01",
                name: "NIGHT FLASH",
                category: "DigiCam",
                isPro: true,
                defaultIntensity: 0.9,
                saturation: 20.0,
                contrast: 26.0,
                warmth: -4.0,
                fade: 0.02,
                shadowTint: [0.02, 0.02, 0.06],
                highlightTint: [0.15, 0.12, 0.10],
                grain: 16.0
            ),
            Preset(
                id: "golden_01",
                name: "GOLDEN '70s",
                category: "Retro",
                isPro: false,
                defaultIntensity: 0.9,
                saturation: -10.0,
                contrast: 14.0,
                warmth: 32.0,
                fade: 0.12,
                shadowTint: [0.10, 0.06, 0.02],
                highlightTint: [0.14, 0.10, 0.03],
                grain: 26.0
            ),
            Preset(
                id: "cyber_01",
                name: "CYBER Y2K",
                category: "Y2K",
                isPro: true,
                defaultIntensity: 0.92,
                saturation: 28.0,
                contrast: 20.0,
                warmth: -12.0,
                fade: 0.05,
                shadowTint: [0.08, 0.0, 0.14],
                highlightTint: [0.12, 0.02, 0.12],
                grain: 14.0
            ),
            Preset(
                id: "noir_01",
                name: "NOIR CLASSIC",
                category: "Minimal",
                isPro: false,
                defaultIntensity: 1.0,
                saturation: -100.0,
                contrast: 22.0,
                warmth: 0.0,
                fade: 0.02,
                shadowTint: [0.0, 0.0, 0.0],
                highlightTint: [0.02, 0.02, 0.02],
                grain: 18.0
            )
        ]
    }
}
