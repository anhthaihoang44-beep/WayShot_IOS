import UIKit
import Photos

public enum PhotoLibrarySaver {

    public enum SaveError: LocalizedError {
        case permissionDenied
        case failedToCreateAsset
        case saveFailed(String)

        public var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Photo library access permission denied"
            case .failedToCreateAsset:
                return "Could not create photo asset in library"
            case .saveFailed(let msg):
                return msg
            }
        }
    }

    public static func saveImageToGallery(
        image: UIImage,
        format: ExportFormat = .jpeg,
        quality: Float = 0.95
    ) async throws -> URL? {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw SaveError.permissionDenied
        }

        // Prepare temporary file
        let ext = format == .png ? "png" : "jpg"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("WAYSHOT_\(Int(Date().timeIntervalSince1970)).\(ext)")

        let data: Data?
        if format == .png {
            data = image.pngData()
        } else {
            data = image.jpegData(compressionQuality: CGFloat(quality))
        }

        guard let fileData = data else {
            throw SaveError.saveFailed("Failed to encode image data")
        }

        try fileData.write(to: fileURL)

        // Save to Photos Album "WayShot"
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, fileURL: fileURL, options: nil)
        }

        return fileURL
    }
}

public enum ExportFormat: String, CaseIterable, Identifiable {
    case jpeg = "JPEG"
    case png = "PNG"

    public var id: String { rawValue }
    public var label: String { rawValue }
    public var subtitle: String {
        switch self {
        case .jpeg: return "Standard"
        case .png: return "Lossless"
        }
    }
}
