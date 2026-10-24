import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

public final class WayShotCoreImagePipeline {

    public static let shared = WayShotCoreImagePipeline()
    private let ciContext: CIContext

    public init() {
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.ciContext = CIContext(mtlDevice: metalDevice, options: [
                .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                .cacheIntermediates: false
            ])
        } else {
            self.ciContext = CIContext(options: [
                .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
            ])
        }
    }

    /// Renders an input UIImage through the aesthetic editing pipeline
    public func render(
        image: UIImage,
        state: EditState,
        preset: Preset?,
        isComparingOriginal: Bool = false,
        splitPosition: Float = -1.0
    ) -> UIImage {
        if isComparingOriginal {
            return image
        }

        guard let cgImage = image.cgImage else { return image }
        let width = cgImage.width
        let height = cgImage.height

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return image }
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var rawData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return image
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Pre-calculate adjustment parameters matching Android GLSL
        let adj = state.adjustments
        let uBrightness = adj.brightness / 250.0
        let uContrast = 1.0 + adj.contrast / 100.0
        let uSaturation = 1.0 + adj.saturation / 100.0
        let uWarmth = adj.warmth / 500.0
        let uHighlights = adj.highlights / 300.0
        let uShadows = adj.shadows / 300.0

        let hasPreset = (preset != nil && state.presetIntensity > 0.001)
        let pIntensity = state.presetIntensity
        let pSat = (preset?.saturation ?? 0.0)
        let pCon = (preset?.contrast ?? 0.0)
        let pWarmth = (preset?.warmth ?? 0.0) / 500.0
        let pFade = (preset?.fade ?? 0.0)
        let pShadowTint = preset?.shadowTint ?? [0.0, 0.0, 0.0]
        let pHighlightTint = preset?.highlightTint ?? [0.0, 0.0, 0.0]
        let pGrain = (preset?.grain ?? 0.0)

        let fx = state.effects
        let totalGrain = (fx.grain / 100.0) + (hasPreset ? pGrain * 0.01 * pIntensity : 0.0)
        let vhsIntensity = fx.vhs / 100.0

        let borderType = state.border.type
        let borderWidth = state.border.widthPercent

        let splitX = splitPosition
        let hasCustomCurves = !state.curves.isLinear()
        let hasCustomHsl = !state.hsl.isDefault()

        // Process pixel data matching Shaders.kt & ADR-003 non-destructive specification
        let totalPixels = width * height
        for i in 0..<totalPixels {
            let offset = i * 4
            let x = i % width
            let y = i / width

            let u = Float(x) / Float(width)
            let v = Float(y) / Float(height)

            // Split line check (Right side is raw original Before)
            if splitX >= 0.0 && u > splitX {
                continue
            }

            var r = Float(rawData[offset]) / 255.0
            var g = Float(rawData[offset + 1]) / 255.0
            var b = Float(rawData[offset + 2]) / 255.0

            // 1. Adjustments
            var luma = 0.2126 * r + 0.7152 * g + 0.0722 * b

            // Brightness
            r += uBrightness
            g += uBrightness
            b += uBrightness

            // Contrast around 0.5
            r = (r - 0.5) * uContrast + 0.5
            g = (g - 0.5) * uContrast + 0.5
            b = (b - 0.5) * uContrast + 0.5

            // Warmth
            r += uWarmth
            b -= uWarmth

            // Shadows and Highlights
            let sCoeff = (1.0 - luma) * (1.0 - luma)
            let hCoeff = luma * luma
            let shAdj = uShadows * sCoeff + uHighlights * hCoeff
            r += shAdj
            g += shAdj
            b += shAdj

            // Saturation
            luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
            r = luma + (r - luma) * uSaturation
            g = luma + (g - luma) * uSaturation
            b = luma + (b - luma) * uSaturation

            r = max(0.0, min(1.0, r))
            g = max(0.0, min(1.0, g))
            b = max(0.0, min(1.0, b))

            // 2. Master & RGB Curves (ADR-004 / ADR-007)
            if hasCustomCurves {
                r = Self.evaluateCurve(points: state.curves.rgb, value: r)
                g = Self.evaluateCurve(points: state.curves.rgb, value: g)
                b = Self.evaluateCurve(points: state.curves.rgb, value: b)

                r = Self.evaluateCurve(points: state.curves.red, value: r)
                g = Self.evaluateCurve(points: state.curves.green, value: g)
                b = Self.evaluateCurve(points: state.curves.blue, value: b)
            }

            // 3. 8-Band HSL Fine Adjustment (ADR-004 / ADR-007)
            if hasCustomHsl {
                let (h, s, l) = Self.rgbToHsl(r: r, g: g, b: b)
                let band = Self.bandForHue(h)
                if let channel = state.hsl.bands[band], (channel.hue != 0 || channel.saturation != 0 || channel.luminance != 0) {
                    var newH = (h + channel.hue).truncatingRemainder(dividingBy: 360.0)
                    if newH < 0 { newH += 360.0 }
                    let newS = max(0.0, min(1.0, s * (1.0 + channel.saturation / 100.0)))
                    let newL = max(0.0, min(1.0, l + channel.luminance / 200.0))
                    let (newR, newG, newB) = Self.hslToRgb(h: newH, s: newS, l: newL)
                    r = newR
                    g = newG
                    b = newB
                }
            }

            let adjR = r
            let adjG = g
            let adjB = b

            // 4. Preset Filter (ADR-005 Shared Preset Format)
            if hasPreset {
                var pR = adjR
                var pG = adjG
                var pB = adjB
                let pLuma = 0.2126 * pR + 0.7152 * pG + 0.0722 * pB

                // Preset Saturation
                let pSatFactor = 1.0 + pSat / 100.0
                pR = pLuma + (pR - pLuma) * pSatFactor
                pG = pLuma + (pG - pLuma) * pSatFactor
                pB = pLuma + (pB - pLuma) * pSatFactor

                // Preset Contrast
                let pConFactor = 1.0 + pCon / 100.0
                pR = (pR - 0.5) * pConFactor + 0.5
                pG = (pG - 0.5) * pConFactor + 0.5
                pB = (pB - 0.5) * pConFactor + 0.5

                // Preset Warmth
                pR += pWarmth
                pB -= pWarmth

                // Preset Fade
                pR = pR * (1.0 - pFade) + pFade
                pG = pG * (1.0 - pFade) + pFade
                pB = pB * (1.0 - pFade) + pFade

                // Tint
                let sWeight = (1.0 - pLuma) * (1.0 - pLuma)
                let hWeight = pLuma * pLuma
                pR += (pShadowTint.indices.contains(0) ? pShadowTint[0] : 0.0) * sWeight + (pHighlightTint.indices.contains(0) ? pHighlightTint[0] : 0.0) * hWeight
                pG += (pShadowTint.indices.contains(1) ? pShadowTint[1] : 0.0) * sWeight + (pHighlightTint.indices.contains(1) ? pHighlightTint[1] : 0.0) * hWeight
                pB += (pShadowTint.indices.contains(2) ? pShadowTint[2] : 0.0) * sWeight + (pHighlightTint.indices.contains(2) ? pHighlightTint[2] : 0.0) * hWeight

                pR = max(0.0, min(1.0, pR))
                pG = max(0.0, min(1.0, pG))
                pB = max(0.0, min(1.0, pB))

                // Lerp by intensity
                r = adjR * (1.0 - pIntensity) + pR * pIntensity
                g = adjG * (1.0 - pIntensity) + pG * pIntensity
                b = adjB * (1.0 - pIntensity) + pB * pIntensity
            }

            // 5. Effects: Grain & VHS
            if totalGrain > 0.001 {
                let pseudoNoise = (sin(u * 12.9898 + v * 78.233) * 43758.5453).truncatingRemainder(dividingBy: 1.0) - 0.5
                let noise = pseudoNoise * totalGrain * 0.35
                r = max(0.0, min(1.0, r + noise))
                g = max(0.0, min(1.0, g + noise))
                b = max(0.0, min(1.0, b + noise))
            }

            if vhsIntensity > 0.001 {
                let scanline = sin(v * 700.0) * 0.04 * vhsIntensity
                r = max(0.0, min(1.0, r - scanline))
                g = max(0.0, min(1.0, g - scanline))
                b = max(0.0, min(1.0, b - scanline))
            }

            // 6. Borders
            if borderType == .polaroid {
                let topBorder = borderWidth * 0.6
                let sideBorder = borderWidth * 0.6
                let bottomBorder = borderWidth * 2.2
                if u < sideBorder || u > (1.0 - sideBorder) || v < topBorder || v > (1.0 - bottomBorder) {
                    r = 0.96; g = 0.95; b = 0.93 // Kem Polaroid
                }
            } else if borderType == .filmStrip {
                let side = borderWidth * 1.0
                if u < side || u > (1.0 - side) {
                    r = 0.08; g = 0.08; b = 0.09
                    let sp = (v * 14.0).truncatingRemainder(dividingBy: 1.0)
                    if sp > 0.3 && sp < 0.7 {
                        if (u > side * 0.25 && u < side * 0.75) ||
                            (u > (1.0 - side * 0.75) && u < (1.0 - side * 0.25)) {
                            r = 0.92; g = 0.92; b = 0.92
                        }
                    }
                }
            } else if borderType == .minimalWhite {
                if u < borderWidth || u > (1.0 - borderWidth) || v < borderWidth || v > (1.0 - borderWidth) {
                    r = 1.0; g = 1.0; b = 1.0
                }
            } else if borderType == .minimalBlack {
                if u < borderWidth || u > (1.0 - borderWidth) || v < borderWidth || v > (1.0 - borderWidth) {
                    r = 0.0; g = 0.0; b = 0.0
                }
            }

            rawData[offset] = UInt8(max(0.0, min(255.0, r * 255.0)))
            rawData[offset + 1] = UInt8(max(0.0, min(255.0, g * 255.0)))
            rawData[offset + 2] = UInt8(max(0.0, min(255.0, b * 255.0)))
        }

        guard let outputCGImage = context.makeImage() else { return image }
        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - Mathematical Helpers for Curves & HSL

    public static func evaluateCurve(points: [CurvePoint], value: Float) -> Float {
        guard !points.isEmpty else { return value }
        if value <= points.first!.x { return points.first!.y }
        if value >= points.last!.x { return points.last!.y }
        for i in 0..<(points.count - 1) {
            let p0 = points[i]
            let p1 = points[i + 1]
            if value >= p0.x && value <= p1.x {
                let range = max(0.0001, p1.x - p0.x)
                let t = (value - p0.x) / range
                return p0.y + t * (p1.y - p0.y)
            }
        }
        return value
    }

    public static func rgbToHsl(r: Float, g: Float, b: Float) -> (h: Float, s: Float, l: Float) {
        let maxVal = max(r, max(g, b))
        let minVal = min(r, min(g, b))
        let delta = maxVal - minVal
        var h: Float = 0
        var s: Float = 0
        let l: Float = (maxVal + minVal) / 2.0

        if delta > 0.0001 {
            s = l > 0.5 ? delta / (2.0 - maxVal - minVal) : delta / (maxVal + minVal)
            if maxVal == r {
                h = ((g - b) / delta) + (g < b ? 6.0 : 0.0)
            } else if maxVal == g {
                h = ((b - r) / delta) + 2.0
            } else {
                h = ((r - g) / delta) + 4.0
            }
            h *= 60.0
        }
        return (h, s, l)
    }

    public static func hslToRgb(h: Float, s: Float, l: Float) -> (r: Float, g: Float, b: Float) {
        if s < 0.0001 {
            return (l, l, l)
        }
        let q = l < 0.5 ? l * (1.0 + s) : l + s - l * s
        let p = 2.0 * l - q
        let hk = h / 360.0
        let tr = (hk + 1.0 / 3.0).truncatingRemainder(dividingBy: 1.0)
        let tg = hk.truncatingRemainder(dividingBy: 1.0)
        let tb = (hk - 1.0 / 3.0 + 1.0).truncatingRemainder(dividingBy: 1.0)

        func hueToRgb(_ t: Float) -> Float {
            var tc = t
            if tc < 0 { tc += 1.0 }
            if tc > 1 { tc -= 1.0 }
            if tc < 1.0 / 6.0 { return p + (q - p) * 6.0 * tc }
            if tc < 1.0 / 2.0 { return q }
            if tc < 2.0 / 3.0 { return p + (q - p) * (2.0 / 3.0 - tc) * 6.0 }
            return p
        }

        return (hueToRgb(tr), hueToRgb(tg), hueToRgb(tb))
    }

    public static func bandForHue(_ hue: Float) -> HslBand {
        let h = hue.truncatingRemainder(dividingBy: 360.0)
        switch h {
        case 345...360, 0..<15: return .red
        case 15..<45: return .orange
        case 45..<75: return .yellow
        case 75..<165: return .green
        case 165..<195: return .aqua
        case 195..<255: return .blue
        case 255..<285: return .purple
        case 285..<345: return .magenta
        default: return .red
        }
    }
}
