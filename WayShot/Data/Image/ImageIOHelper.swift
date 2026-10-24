import UIKit
import ImageIO

public enum ImageIOHelper {

    /// Decodes a downsampled preview image (max side 1080 - 1440px) to guarantee 60fps and low memory footprint (ADR-009)
    public static func decodeDownsampledImage(from url: URL, maxDimension: CGFloat = 1440) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
            return UIImage(contentsOfFile: url.path)
        }

        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ] as [CFString: Any] as CFDictionary

        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else {
            return UIImage(contentsOfFile: url.path)
        }

        return UIImage(cgImage: downsampledImage)
    }

    /// Decodes a downsampled preview image from UIImage
    public static func downsample(image: UIImage, maxDimension: CGFloat = 1440) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }

        let scale = maxDimension / maxSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    /// Decodes a full-resolution image for export (ADR-009)
    public static func decodeFullResolutionImage(from url: URL) -> UIImage? {
        let options = [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, options),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, options) else {
            return UIImage(contentsOfFile: url.path)
        }
        return UIImage(cgImage: cgImage)
    }
}
