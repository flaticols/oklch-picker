import Foundation
import AppKit
import Combine

class ColorPickerViewModel: ObservableObject {
    // OKLCH components
    @Published var lightness: Double = 0.7 {
        didSet { updateColor() }
    }

    @Published var chroma: Double = 0.15 {
        didSet { updateColor() }
    }

    @Published var hue: Double = 180.0 {
        didSet { updateColor() }
    }

    @Published var alpha: Double = 1.0 {
        didSet { updateColor() }
    }

    // Output
    @Published var currentColor: NSColor = .blue
    @Published var selectedFormat: ColorFormat = .oklch
    @Published var formattedColor: String = ""
    @Published var isInSRGBGamut: Bool = true
    @Published var inputText: String = ""
    @Published var inputError: String? = nil

    // Constraints
    let maxChroma: Double = 0.4

    init() {
        updateColor()
    }

    // MARK: - Update Color

    private func updateColor() {
        let oklch = OKLCHColor(
            lightness: lightness,
            chroma: chroma,
            hue: hue,
            alpha: alpha
        )

        currentColor = ColorConverter.oklchToNSColor(oklch)
        formattedColor = ColorFormatter.format(oklch, as: selectedFormat)
        isInSRGBGamut = ColorConverter.isInSRGBGamut(oklch)
    }

    // MARK: - Format Change

    func updateFormat(_ format: ColorFormat) {
        selectedFormat = format
        updateColor()
    }

    // MARK: - Copy to Clipboard

    func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(formattedColor, forType: .string)
    }

    // MARK: - Random Color

    func randomColor() {
        lightness = Double.random(in: 0.3...0.9)
        chroma = Double.random(in: 0.05...0.25)
        hue = Double.random(in: 0...360)
        alpha = 1.0
    }

    // MARK: - Parse Input

    func parseInput() {
        inputError = nil

        guard !inputText.isEmpty else {
            inputError = "Please enter a color value"
            return
        }

        if let oklch = ColorFormatter.parseColorString(inputText) {
            lightness = oklch.lightness
            chroma = oklch.chroma
            hue = oklch.hue
            alpha = oklch.alpha
            inputText = ""
        } else {
            inputError = "Invalid color format"
        }
    }

    // MARK: - Import from NSColorPanel

    func importFromColorPanel() {
        let colorPanel = NSColorPanel.shared
        colorPanel.showsAlpha = true
        colorPanel.isContinuous = true

        if let oklch = ColorConverter.nsColorToOKLCH(colorPanel.color) {
            lightness = oklch.lightness
            chroma = min(oklch.chroma, maxChroma)
            hue = oklch.hue
            alpha = oklch.alpha
        }
    }

    // MARK: - Helper Methods

    var oklchColor: OKLCHColor {
        OKLCHColor(lightness: lightness, chroma: chroma, hue: hue, alpha: alpha)
    }

    var gamutStatus: String {
        isInSRGBGamut ? "✓ In sRGB gamut" : "⚠ Outside sRGB gamut"
    }

    var gamutStatusColor: NSColor {
        isInSRGBGamut ? .systemGreen : .systemOrange
    }
}
