import UIKit

public enum SampleImageGenerator {

    public static func generateAestheticSampleImage(width: Int = 1080, height: Int = 1350) -> UIImage {
        let size = CGSize(width: width, height: height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            let cgContext = context.cgContext
            let colorSpace = CGColorSpaceCreateDeviceRGB()

            // 1. Sky Gradient: Deep twilight violet to warm sunset coral
            let skyColors: [CGColor] = [
                UIColor(red: 36/255.0, green: 42/255.0, blue: 74/255.0, alpha: 1.0).cgColor,    // Twilight Navy
                UIColor(red: 108/255.0, green: 63/255.0, blue: 114/255.0, alpha: 1.0).cgColor,  // Dusk Purple
                UIColor(red: 209/255.0, green: 98/255.0, blue: 107/255.0, alpha: 1.0).cgColor,  // Coral Pink
                UIColor(red: 243/255.0, green: 168/255.0, blue: 112/255.0, alpha: 1.0).cgColor, // Sunset Peach
                UIColor(red: 253/255.0, green: 230/255.0, blue: 138/255.0, alpha: 1.0).cgColor  // Golden Warm Horizon
            ]
            let skyLocations: [CGFloat] = [0.0, 0.35, 0.60, 0.85, 1.0]
            if let skyGradient = CGGradient(colorsSpace: colorSpace, colors: skyColors as CFArray, locations: skyLocations) {
                cgContext.drawLinearGradient(
                    skyGradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: 0, y: CGFloat(height) * 0.75),
                    options: [.drawsAfterEndLocation]
                )
            }

            // 2. Soft Ambient Golden Sun Glow
            let sunCenter = CGPoint(x: CGFloat(width) * 0.5, y: CGFloat(height) * 0.52)
            let sunRadius = CGFloat(width) * 0.45
            let sunGlowColors: [CGColor] = [
                UIColor(red: 255/255.0, green: 245/255.0, blue: 205/255.0, alpha: 0.90).cgColor,
                UIColor(red: 255/255.0, green: 175/255.0, blue: 90/255.0, alpha: 0.47).cgColor,
                UIColor(red: 240/255.0, green: 120/255.0, blue: 80/255.0, alpha: 0.0).cgColor
            ]
            let sunGlowLocations: [CGFloat] = [0.0, 0.45, 1.0]
            if let sunGlowGradient = CGGradient(colorsSpace: colorSpace, colors: sunGlowColors as CFArray, locations: sunGlowLocations) {
                cgContext.drawRadialGradient(
                    sunGlowGradient,
                    startCenter: sunCenter,
                    startRadius: 0,
                    endCenter: sunCenter,
                    endRadius: sunRadius,
                    options: []
                )
            }

            // 3. Crisp Sun Core
            cgContext.setFillColor(UIColor(red: 255/255.0, green: 252/255.0, blue: 235/255.0, alpha: 1.0).cgColor)
            let coreRadius = CGFloat(width) * 0.11
            cgContext.fillEllipse(in: CGRect(
                x: sunCenter.x - coreRadius,
                y: sunCenter.y - coreRadius,
                width: coreRadius * 2,
                height: coreRadius * 2
            ))

            // 4. Distant Mist Layer
            let mistColors: [CGColor] = [
                UIColor(red: 253/255.0, green: 230/255.0, blue: 138/255.0, alpha: 0.0).cgColor,
                UIColor(red: 243/255.0, green: 168/255.0, blue: 112/255.0, alpha: 0.55).cgColor
            ]
            if let mistGradient = CGGradient(colorsSpace: colorSpace, colors: mistColors as CFArray, locations: [0.0, 1.0]) {
                cgContext.saveGState()
                let mistRect = CGRect(x: 0, y: CGFloat(height) * 0.55, width: CGFloat(width), height: CGFloat(height) * 0.17)
                cgContext.clip(to: mistRect)
                cgContext.drawLinearGradient(
                    mistGradient,
                    start: CGPoint(x: 0, y: CGFloat(height) * 0.55),
                    end: CGPoint(x: 0, y: CGFloat(height) * 0.72),
                    options: []
                )
                cgContext.restoreGState()
            }

            // 5. Layer 1: Distant Mountain Silhouette
            let mountainPath1 = CGMutablePath()
            mountainPath1.move(to: CGPoint(x: 0, y: CGFloat(height) * 0.65))
            mountainPath1.addLine(to: CGPoint(x: CGFloat(width) * 0.22, y: CGFloat(height) * 0.58))
            mountainPath1.addLine(to: CGPoint(x: CGFloat(width) * 0.45, y: CGFloat(height) * 0.63))
            mountainPath1.addLine(to: CGPoint(x: CGFloat(width) * 0.72, y: CGFloat(height) * 0.57))
            mountainPath1.addLine(to: CGPoint(x: CGFloat(width), y: CGFloat(height) * 0.64))
            mountainPath1.addLine(to: CGPoint(x: CGFloat(width), y: CGFloat(height)))
            mountainPath1.addLine(to: CGPoint(x: 0, y: CGFloat(height)))
            mountainPath1.closeSubpath()

            let m1Colors: [CGColor] = [
                UIColor(red: 102/255.0, green: 58/255.0, blue: 88/255.0, alpha: 1.0).cgColor,
                UIColor(red: 65/255.0, green: 38/255.0, blue: 62/255.0, alpha: 1.0).cgColor
            ]
            if let m1Grad = CGGradient(colorsSpace: colorSpace, colors: m1Colors as CFArray, locations: [0.0, 1.0]) {
                cgContext.saveGState()
                cgContext.addPath(mountainPath1)
                cgContext.clip()
                cgContext.drawLinearGradient(
                    m1Grad,
                    start: CGPoint(x: 0, y: CGFloat(height) * 0.57),
                    end: CGPoint(x: 0, y: CGFloat(height)),
                    options: []
                )
                cgContext.restoreGState()
            }

            // 6. Layer 2: Foreground Hill Silhouette
            let mountainPath2 = CGMutablePath()
            mountainPath2.move(to: CGPoint(x: 0, y: CGFloat(height) * 0.74))
            mountainPath2.addCurve(
                to: CGPoint(x: CGFloat(width), y: CGFloat(height) * 0.72),
                control1: CGPoint(x: CGFloat(width) * 0.3, y: CGFloat(height) * 0.68),
                control2: CGPoint(x: CGFloat(width) * 0.5, y: CGFloat(height) * 0.78)
            )
            mountainPath2.addLine(to: CGPoint(x: CGFloat(width), y: CGFloat(height)))
            mountainPath2.addLine(to: CGPoint(x: 0, y: CGFloat(height)))
            mountainPath2.closeSubpath()

            let m2Colors: [CGColor] = [
                UIColor(red: 42/255.0, green: 25/255.0, blue: 48/255.0, alpha: 1.0).cgColor,
                UIColor(red: 20/255.0, green: 12/255.0, blue: 25/255.0, alpha: 1.0).cgColor
            ]
            if let m2Grad = CGGradient(colorsSpace: colorSpace, colors: m2Colors as CFArray, locations: [0.0, 1.0]) {
                cgContext.saveGState()
                cgContext.addPath(mountainPath2)
                cgContext.clip()
                cgContext.drawLinearGradient(
                    m2Grad,
                    start: CGPoint(x: 0, y: CGFloat(height) * 0.68),
                    end: CGPoint(x: 0, y: CGFloat(height)),
                    options: []
                )
                cgContext.restoreGState()
            }

            // 7. Minimalist Pines Silhouettes on the Foreground Ridge
            cgContext.setFillColor(UIColor(red: 22/255.0, green: 14/255.0, blue: 28/255.0, alpha: 1.0).cgColor)
            let treePositions: [CGFloat] = [0.12, 0.16, 0.22, 0.26, 0.82, 0.88]
            for treeXRel in treePositions {
                let treeX = CGFloat(width) * treeXRel
                let treeBaseY = CGFloat(height) * 0.76
                let treeHeight = CGFloat(height) * 0.07
                let halfW = CGFloat(width) * 0.022

                let treePath = CGMutablePath()
                treePath.move(to: CGPoint(x: treeX, y: treeBaseY - treeHeight))
                treePath.addLine(to: CGPoint(x: treeX + halfW, y: treeBaseY))
                treePath.addLine(to: CGPoint(x: treeX - halfW, y: treeBaseY))
                treePath.closeSubpath()

                cgContext.addPath(treePath)
                cgContext.fillPath()
            }
        }
    }
}
