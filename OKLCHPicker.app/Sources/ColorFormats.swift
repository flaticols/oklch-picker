import Foundation
import AppKit

enum ColorFormat: String, CaseIterable {
    case oklch = "OKLCH"
    case hex = "HEX"
    case rgb = "RGB"
    case hsl = "HSL"
    case oklab = "Oklab"
    case numbers = "Numbers"

    var description: String {
        return self.rawValue
    }
}

class ColorFormatter {

    // MARK: - Format OKLCH

    static func formatOKLCH(_ oklch: OKLCHColor) -> String {
        let l = ColorConverter.round(oklch.lightness, to: 4)
        let c = ColorConverter.round(oklch.chroma, to: 4)
        let h = ColorConverter.round(oklch.hue, to: 2)

        if oklch.alpha < 1.0 {
            let a = ColorConverter.round(oklch.alpha * 100, to: 0)
            return "oklch(\(l) \(c) \(h) / \(Int(a))%)"
        } else {
            return "oklch(\(l) \(c) \(h))"
        }
    }

    // MARK: - Format HEX

    static func formatHex(_ oklch: OKLCHColor) -> String {
        let rgb = ColorConverter.oklchToRGB(oklch)

        let r = Int(round(clampValue(rgb.r) * 255))
        let g = Int(round(clampValue(rgb.g) * 255))
        let b = Int(round(clampValue(rgb.b) * 255))

        if oklch.alpha < 1.0 {
            let a = Int(round(oklch.alpha * 255))
            return String(format: "#%02X%02X%02X%02X", r, g, b, a)
        } else {
            return String(format: "#%02X%02X%02X", r, g, b)
        }
    }

    // MARK: - Format RGB

    static func formatRGB(_ oklch: OKLCHColor) -> String {
        let rgb = ColorConverter.oklchToRGB(oklch)

        let r = Int(round(clampValue(rgb.r) * 255))
        let g = Int(round(clampValue(rgb.g) * 255))
        let b = Int(round(clampValue(rgb.b) * 255))

        if oklch.alpha < 1.0 {
            let a = ColorConverter.round(oklch.alpha, to: 2)
            return "rgba(\(r), \(g), \(b), \(a))"
        } else {
            return "rgb(\(r), \(g), \(b))"
        }
    }

    // MARK: - Format HSL

    static func formatHSL(_ oklch: OKLCHColor) -> String {
        let rgb = ColorConverter.oklchToRGB(oklch)
        let hsl = rgbToHSL(rgb)

        let h = Int(round(hsl.h))
        let s = Int(round(hsl.s * 100))
        let l = Int(round(hsl.l * 100))

        if oklch.alpha < 1.0 {
            let a = ColorConverter.round(oklch.alpha, to: 2)
            return "hsla(\(h), \(s)%, \(l)%, \(a))"
        } else {
            return "hsl(\(h), \(s)%, \(l)%)"
        }
    }

    // MARK: - Format Oklab

    static func formatOklab(_ oklch: OKLCHColor) -> String {
        let hueRadians = oklch.hue * .pi / 180.0
        let a = oklch.chroma * cos(hueRadians)
        let b = oklch.chroma * sin(hueRadians)

        let L = ColorConverter.round(oklch.lightness, to: 4)
        let aVal = ColorConverter.round(a, to: 4)
        let bVal = ColorConverter.round(b, to: 4)

        if oklch.alpha < 1.0 {
            let alpha = ColorConverter.round(oklch.alpha, to: 2)
            return "oklab(\(L) \(aVal) \(bVal) / \(alpha))"
        } else {
            return "oklab(\(L) \(aVal) \(bVal))"
        }
    }

    // MARK: - Format Numbers

    static func formatNumbers(_ oklch: OKLCHColor) -> String {
        let l = ColorConverter.round(oklch.lightness, to: 4)
        let c = ColorConverter.round(oklch.chroma, to: 4)
        let h = ColorConverter.round(oklch.hue, to: 2)

        if oklch.alpha < 1.0 {
            let a = ColorConverter.round(oklch.alpha * 100, to: 0)
            return "\(l), \(c), \(h), \(Int(a))"
        } else {
            return "\(l), \(c), \(h)"
        }
    }

    // MARK: - Format by Type

    static func format(_ oklch: OKLCHColor, as format: ColorFormat) -> String {
        switch format {
        case .oklch:
            return formatOKLCH(oklch)
        case .hex:
            return formatHex(oklch)
        case .rgb:
            return formatRGB(oklch)
        case .hsl:
            return formatHSL(oklch)
        case .oklab:
            return formatOklab(oklch)
        case .numbers:
            return formatNumbers(oklch)
        }
    }

    // MARK: - Helper Functions

    private static func clampValue(_ value: Double) -> Double {
        return min(max(value, 0.0), 1.0)
    }

    private static func rgbToHSL(_ rgb: RGBColor) -> (h: Double, s: Double, l: Double) {
        let r = clampValue(rgb.r)
        let g = clampValue(rgb.g)
        let b = clampValue(rgb.b)

        let maxVal = max(r, g, b)
        let minVal = min(r, g, b)
        let delta = maxVal - minVal

        var h: Double = 0
        var s: Double = 0
        let l = (maxVal + minVal) / 2

        if delta != 0 {
            s = l > 0.5 ? delta / (2 - maxVal - minVal) : delta / (maxVal + minVal)

            switch maxVal {
            case r:
                h = ((g - b) / delta) + (g < b ? 6 : 0)
            case g:
                h = ((b - r) / delta) + 2
            case b:
                h = ((r - g) / delta) + 4
            default:
                break
            }

            h *= 60
        }

        return (h: h, s: s, l: l)
    }

    // MARK: - Parse Color String

    static func parseColorString(_ string: String) -> OKLCHColor? {
        let trimmed = string.trimmingCharacters(in: .whitespaces).lowercased()

        // Try parsing hex
        if let color = parseHex(trimmed) {
            return color
        }

        // Try parsing OKLCH
        if let color = parseOKLCH(trimmed) {
            return color
        }

        // Try parsing RGB
        if let color = parseRGB(trimmed) {
            return color
        }

        return nil
    }

    private static func parseHex(_ string: String) -> OKLCHColor? {
        var hex = string
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }

        guard hex.count == 6 || hex.count == 8 else { return nil }

        var rgb: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&rgb) else { return nil }

        let r: Double
        let g: Double
        let b: Double
        let a: Double

        if hex.count == 6 {
            r = Double((rgb >> 16) & 0xFF) / 255.0
            g = Double((rgb >> 8) & 0xFF) / 255.0
            b = Double(rgb & 0xFF) / 255.0
            a = 1.0
        } else {
            r = Double((rgb >> 24) & 0xFF) / 255.0
            g = Double((rgb >> 16) & 0xFF) / 255.0
            b = Double((rgb >> 8) & 0xFF) / 255.0
            a = Double(rgb & 0xFF) / 255.0
        }

        let rgbColor = RGBColor(r: r, g: g, b: b, alpha: a)
        return ColorConverter.rgbToOKLCH(rgbColor)
    }

    private static func parseOKLCH(_ string: String) -> OKLCHColor? {
        let pattern = #"oklch\(\s*([\d.]+)\s+([\d.]+)\s+([\d.]+)(?:\s*\/\s*([\d.]+)%?)?\s*\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)) else {
            return nil
        }

        let l = extractDouble(from: string, at: match.range(at: 1))
        let c = extractDouble(from: string, at: match.range(at: 2))
        let h = extractDouble(from: string, at: match.range(at: 3))
        var a = 1.0

        if match.range(at: 4).location != NSNotFound {
            a = extractDouble(from: string, at: match.range(at: 4)) / 100.0
        }

        return OKLCHColor(lightness: l, chroma: c, hue: h, alpha: a)
    }

    private static func parseRGB(_ string: String) -> OKLCHColor? {
        let pattern = #"rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\s*\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)) else {
            return nil
        }

        let r = extractDouble(from: string, at: match.range(at: 1)) / 255.0
        let g = extractDouble(from: string, at: match.range(at: 2)) / 255.0
        let b = extractDouble(from: string, at: match.range(at: 3)) / 255.0
        var a = 1.0

        if match.range(at: 4).location != NSNotFound {
            a = extractDouble(from: string, at: match.range(at: 4))
        }

        let rgb = RGBColor(r: r, g: g, b: b, alpha: a)
        return ColorConverter.rgbToOKLCH(rgb)
    }

    private static func extractDouble(from string: String, at range: NSRange) -> Double {
        guard let range = Range(range, in: string) else { return 0 }
        return Double(string[range]) ?? 0
    }
}
