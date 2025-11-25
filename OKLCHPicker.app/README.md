# OKLCH Color Picker - macOS Native App

A native macOS application for picking and converting colors using the OKLCH color space, built with Swift and SwiftUI.

## Features

- **OKLCH Color Space**: Pick colors using the perceptually uniform OKLCH color space
- **Interactive Sliders**: Adjust Lightness (L), Chroma (C), Hue (H), and Alpha independently
- **Real-time Preview**: See your color with transparency support (checkerboard background)
- **Multiple Export Formats**:
  - OKLCH
  - HEX (with alpha support)
  - RGB/RGBA
  - HSL/HSLA
  - Oklab
  - Numbers only
- **Gamut Detection**: Visual indicator showing if color is within sRGB gamut
- **Color Import**: Parse and import colors from various formats (hex, rgb, oklch)
- **Copy to Clipboard**: One-click copying of formatted color values
- **Random Color Generator**: Generate random colors for inspiration
- **macOS Color Picker Integration**: Import colors from the native macOS color picker

## About OKLCH

OKLCH is a perceptually uniform color space that provides several advantages over traditional color spaces:

- **Perceptually Uniform**: Equal changes in color values produce equal perceptual differences
- **Wide Gamut Support**: Can represent colors beyond sRGB (P3, Rec2020, and beyond)
- **Predictable Contrast**: Unlike HSL, OKLCH maintains predictable contrast when transforming colors
- **No Hue Shift**: Unlike LCH/Lab, changing chroma doesn't cause hue shifts
- **Native Browser Support**: Modern browsers support OKLCH directly in CSS

## Components

### Lightness (L)
Range: 0.0 to 1.0
- 0.0 = Black
- 1.0 = White

### Chroma (C)
Range: 0.0 to 0.4
- 0.0 = Grayscale (no color)
- Higher values = More saturated/vivid colors

### Hue (H)
Range: 0° to 360°
- Color wheel position
- 0°/360° = Red
- 120° = Green
- 240° = Blue

### Alpha
Range: 0.0 to 1.0
- 0.0 = Fully transparent
- 1.0 = Fully opaque

## Building and Running

### Requirements
- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Building with Xcode

1. Open Terminal and navigate to the `OKLCHPicker.app` directory
2. Open the package in Xcode:
   ```bash
   open Package.swift
   ```
3. Wait for Xcode to resolve dependencies
4. Select your Mac as the run destination
5. Press Cmd+R to build and run

### Building from Command Line

```bash
cd OKLCHPicker.app
swift build
swift run OKLCHPicker
```

### Creating a Standalone App

To create a standalone .app bundle:

```bash
cd OKLCHPicker.app
swift build -c release
```

The compiled binary will be in `.build/release/OKLCHPicker`

## Architecture

The app is organized into several key components:

### ColorConversion.swift
Handles all color space conversions:
- OKLCH ↔ Oklab ↔ Linear RGB ↔ sRGB conversions
- Implements the Oklab algorithm by Björn Ottosson
- Gamma correction and inverse gamma functions
- Gamut detection

### ColorFormats.swift
Manages color output formatting:
- Multiple format outputs (OKLCH, HEX, RGB, HSL, Oklab, Numbers)
- Color string parsing for various input formats
- RGB to HSL conversion

### ColorPickerViewModel.swift
View model managing app state:
- Observable object for SwiftUI bindings
- Color component management (L, C, H, Alpha)
- Format selection and output generation
- Input parsing and validation
- Clipboard operations

### ContentView.swift
Main SwiftUI interface:
- Color preview with transparency support
- Interactive sliders for each component
- Format selector and output display
- Import/export functionality
- Random color generator

### main.swift
App entry point and configuration

## Usage

### Picking a Color
1. Use the sliders to adjust Lightness, Chroma, Hue, and Alpha
2. Watch the color preview update in real-time
3. Check the gamut indicator to see if the color is in sRGB

### Exporting a Color
1. Select your desired format from the segmented control
2. The formatted color value appears below
3. Click the copy button to copy to clipboard
4. Paste into your CSS, design tool, or code

### Importing a Color
1. Enter a color value in the text field (supports hex, rgb, rgba, oklch)
2. Click "Parse" or press Enter
3. The sliders will update to match the imported color

### Examples of Supported Input Formats
```
#FF5733
#FF573380
rgb(255, 87, 51)
rgba(255, 87, 51, 0.5)
oklch(0.7 0.15 30)
oklch(0.7 0.15 30 / 80%)
```

## Technical Details

### Color Conversion Algorithm

The app implements the Oklab color space algorithm as specified by Björn Ottosson:
- [Oklab - A perceptual color space for image processing](https://bottosson.github.io/posts/oklab/)

The conversion pipeline:
1. **OKLCH → Oklab**: Convert cylindrical to Cartesian coordinates
2. **Oklab → Linear RGB**: Matrix transformation with cone response
3. **Linear RGB → sRGB**: Apply gamma correction (2.4)
4. **Reverse conversions**: Inverse operations with inverse gamma

### Gamut Detection

The app checks if colors fall within the sRGB gamut by validating that RGB components are within the range [0, 1] with a small tolerance for floating-point precision.

## Comparison with Web Version

This macOS app replicates the core functionality of the web-based OKLCH picker at [oklch.com](https://oklch.com):

**Implemented:**
- ✅ OKLCH color space support
- ✅ Interactive sliders
- ✅ Multiple output formats
- ✅ Color input parsing
- ✅ Gamut detection
- ✅ Alpha channel support
- ✅ Random color generation

**Differences:**
- Native macOS interface instead of web UI
- No 3D color space visualization (web version has optional Three.js 3D model)
- No 2D color charts/maps (simplified to sliders only)
- Native macOS color picker integration instead of web-based picker

## License

This implementation is provided as-is for educational and practical use. The original web version at [oklch.com](https://oklch.com) is maintained by Evil Martians.

## Credits

- **OKLCH Color Space**: Based on Oklab by Björn Ottosson
- **Original Web App**: [Evil Martians](https://evilmartians.com/) - [oklch.com](https://oklch.com)
- **macOS Implementation**: Native Swift/SwiftUI port

## Resources

- [OKLCH in CSS: why we moved from RGB and HSL](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl)
- [Oklab specification](https://bottosson.github.io/posts/oklab/)
- [CSS Color Module Level 4](https://www.w3.org/TR/css-color-4/)
