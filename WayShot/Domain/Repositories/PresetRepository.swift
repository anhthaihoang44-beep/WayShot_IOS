import Foundation

public protocol PresetRepository {
    func getPresets() async throws -> [Preset]
}
