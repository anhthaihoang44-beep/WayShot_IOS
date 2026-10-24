import UIKit

public enum HeadlessImageExporter {

    public static func renderFullResolution(
        sourceImage: UIImage,
        state: EditState,
        preset: Preset?
    ) async -> UIImage {
        return await Task.detached(priority: .userInitiated) {
            WayShotCoreImagePipeline.shared.render(
                image: sourceImage,
                state: state,
                preset: preset,
                isComparingOriginal: false,
                splitPosition: -1.0
            )
        }.value
    }
}
