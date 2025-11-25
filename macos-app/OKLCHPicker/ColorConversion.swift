import Foundation
import AppKit

/// OKLCH Color representation
struct OKLCHColor {
    var lightness: Double  // 0.0 to 1.0
    var chroma: Double     // 0.0 to 0.4+
    var hue: Double        // 0.0 to 360.0
    var alpha: Double      // 0.0 to 1.0

    init(lightness: Double, chroma: Double, hue: Double, alpha: Double = 1.0) {
        self.lightness = lightness
        self.chroma = chroma
        self.hue = hue
        self.alpha = alpha
    }
}

/// RGB Color representation
struct RGBColor {
    var r: Double  // 0.0 to 1.0
    var g: Double
    var b: Double
    var alpha: Double

    init(r: Double, g: Double, b: Double, alpha: Double = 1.0) {
        self.r = r
        self.g = g
        self.b = b
        self.alpha = alpha
    }
}

/// Oklab Color representation (intermediate format)
struct OklabColor {
    var L: Double
    var a: Double
    var b: Double
    var alpha: Double
}

class ColorConverter {

    // MARK: - OKLCH to RGB Conversion

    /// Convert OKLCH to RGB
    static func oklchToRGB(_ oklch: OKLCHColor) -> RGBColor {
        // Step 1: OKLCH to Oklab
        let oklab = oklchToOklab(oklch)

        // Step 2: Oklab to Linear RGB
        let linearRGB = oklabToLinearRGB(oklab)

        // Step 3: Linear RGB to sRGB (gamma correction)
        let srgb = linearRGBToSRGB(linearRGB)

        return srgb
    }

    /// Convert OKLCH to Oklab
    private static func oklchToOklab(_ oklch: OKLCHColor) -> OklabColor {
        let hueRadians = oklch.hue * .pi / 180.0
        let a = oklch.chroma * cos(hueRadians)
        let b = oklch.chroma * sin(hueRadians)

        return OklabColor(L: oklch.lightness, a: a, b: b, alpha: oklch.alpha)
    }

    /// Convert Oklab to Linear RGB
    private static func oklabToLinearRGB(_ oklab: OklabColor) -> RGBColor {
        let L = oklab.L
        let a = oklab.a
        let b = oklab.b

        let l = L + 0.3963377774 * a + 0.2158037573 * b
        let m = L - 0.1055613458 * a - 0.0638541728 * b
        let s = L - 0.0894841775 * a - 1.2914855480 * b

        let l3 = l * l * l
        let m3 = m * m * m
        let s3 = s * s * s

        let r = +4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3
        let g = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3
        let bl = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3

        return RGBColor(r: r, g: g, b: bl, alpha: oklab.alpha)
    }

    /// Apply gamma correction (Linear RGB to sRGB)
    private static func linearRGBToSRGB(_ linear: RGBColor) -> RGBColor {
        func gammaCorrect(_ value: Double) -> Double {
            if value <= 0.0031308 {
                return 12.92 * value
            } else {
                return 1.055 * pow(value, 1.0 / 2.4) - 0.055
            }
        }

        return RGBColor(
            r: gammaCorrect(linear.r),
            g: gammaCorrect(linear.g),
            b: gammaCorrect(linear.b),
            alpha: linear.alpha
        )
    }

    // MARK: - RGB to OKLCH Conversion

    /// Convert RGB to OKLCH
    static func rgbToOKLCH(_ rgb: RGBColor) -> OKLCHColor {
        // Step 1: sRGB to Linear RGB
        let linearRGB = srgbToLinearRGB(rgb)

        // Step 2: Linear RGB to Oklab
        let oklab = linearRGBToOklab(linearRGB)

        // Step 3: Oklab to OKLCH
        let oklch = oklabToOKLCH(oklab)

        return oklch
    }

    /// Remove gamma correction (sRGB to Linear RGB)
    private static func srgbToLinearRGB(_ srgb: RGBColor) -> RGBColor {
        func inverseGamma(_ value: Double) -> Double {
            if value <= 0.04045 {
                return value / 12.92
            } else {
                return pow((value + 0.055) / 1.055, 2.4)
            }
        }

        return RGBColor(
            r: inverseGamma(srgb.r),
            g: inverseGamma(srgb.g),
            b: inverseGamma(srgb.b),
            alpha: srgb.alpha
        )
    }

    /// Convert Linear RGB to Oklab
    private static func linearRGBToOklab(_ rgb: RGBColor) -> OklabColor {
        let r = rgb.r
        let g = rgb.g
        let b = rgb.b

        let l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
        let m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
        let s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

        let lCube = cbrt(l)
        let mCube = cbrt(m)
        let sCube = cbrt(s)

        let L = 0.2104542553 * lCube + 0.7936177850 * mCube - 0.0040720468 * sCube
        let a = 1.9779984951 * lCube - 2.4285922050 * mCube + 0.4505937099 * sCube
        let bVal = 0.0259040371 * lCube + 0.7827717662 * mCube - 0.8086757660 * sCube

        return OklabColor(L: L, a: a, b: bVal, alpha: rgb.alpha)
    }

    /// Convert Oklab to OKLCH
    private static func oklabToOKLCH(_ oklab: OklabColor) -> OKLCHColor {
        let chroma = sqrt(oklab.a * oklab.a + oklab.b * oklab.b)
        var hue = atan2(oklab.b, oklab.a) * 180.0 / .pi

        // Normalize hue to 0-360 range
        if hue < 0 {
            hue += 360
        }

        return OKLCHColor(
            lightness: oklab.L,
            chroma: chroma,
            hue: hue,
            alpha: oklab.alpha
        )
    }

    // MARK: - NSColor Conversions

    /// Convert OKLCH to NSColor
    static func oklchToNSColor(_ oklch: OKLCHColor) -> NSColor {
        let rgb = oklchToRGB(oklch)
        return NSColor(
            red: clamp(rgb.r),
            green: clamp(rgb.g),
            blue: clamp(rgb.b),
            alpha: rgb.alpha
        )
    }

    /// Convert NSColor to OKLCH
    static func nsColorToOKLCH(_ color: NSColor) -> OKLCHColor? {
        guard let rgbColor = color.usingColorSpace(.deviceRGB) else {
            return nil
        }

        let rgb = RGBColor(
            r: Double(rgbColor.redComponent),
            g: Double(rgbColor.greenComponent),
            b: Double(rgbColor.blueComponent),
            alpha: Double(rgbColor.alphaComponent)
        )

        return rgbToOKLCH(rgb)
    }

    // MARK: - Helper Functions

    /// Clamp value between 0 and 1
    private static func clamp(_ value: Double) -> CGFloat {
        return CGFloat(min(max(value, 0.0), 1.0))
    }

    /// Check if color is in sRGB gamut
    static func isInSRGBGamut(_ oklch: OKLCHColor) -> Bool {
        let rgb = oklchToRGB(oklch)
        let threshold = 0.001
        return rgb.r >= -threshold && rgb.r <= 1.0 + threshold &&
               rgb.g >= -threshold && rgb.g <= 1.0 + threshold &&
               rgb.b >= -threshold && rgb.b <= 1.0 + threshold
    }

    /// Round to specified decimal places
    static func round(_ value: Double, to places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (value * multiplier).rounded() / multiplier
    }
}
