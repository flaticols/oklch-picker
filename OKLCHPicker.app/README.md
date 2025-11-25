# OKLCH Color Picker - macOS Native App

A native macOS application for picking and converting colors using the OKLCH color space, built with Swift and SwiftUI.

## Features

### Color Picking
- **OKLCH Color Space**: Pick colors using the perceptually uniform OKLCH color space
- **Interactive Sliders**: Adjust Lightness (L), Chroma (C), Hue (H), and Alpha independently
- **Real-time Preview**: See your color with transparency support (checkerboard background)
- **Gamut Detection**: Visual indicator showing if color is within sRGB gamut

### Visualizations
- **2D Color Charts**: Interactive 2D color plane visualizations
  - Lightness × Chroma (L-C) plane
  - Chroma × Hue (C-H) plane
  - Lightness × Hue (L-H) plane
  - Click/drag to select colors directly from charts
  - Optimized rendering with adaptive resolution
- **3D Color Space**: Full 3D OKLCH color space visualization
  - SceneKit-powered 3D rendering
  - Interactive camera controls (rotate, zoom, pan)
  - Real-time marker showing current color position
  - Cylindrical coordinate system display
  - Only shows colors within sRGB gamut

### Export & Import
- **Multiple Export Formats**:
  - OKLCH: `oklch(0.7 0.15 180)`
  - HEX: `#3399FF` or `#3399FF80` (with alpha)
  - RGB/RGBA: `rgb(51, 153, 255)`
  - HSL/HSLA: `hsl(210, 100%, 60%)`
  - Oklab: `oklab(0.7 -0.05 -0.13)`
  - Numbers: `0.7, 0.15, 180`
- **Color Import**: Parse and import colors from various formats (hex, rgb, oklch)
- **Copy to Clipboard**: One-click copying of formatted color values

### Utilities
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
- Xcode 16.0 or later
- Swift 6.0

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
Main SwiftUI interface with tabbed layout:
- Picker tab: Color preview, sliders, format selector
- 2D Charts tab: Interactive color plane visualizations
- 3D View tab: SceneKit 3D color space visualization
- Import/export functionality
- Random color generator

### ColorChart2D.swift
2D color chart rendering:
- Canvas-based color plane rendering
- Three chart types (L-C, C-H, L-H)
- Async rendering for performance
- Interactive color selection via drag gestures
- Optimized with render debouncing

### ColorSpace3D.swift
3D visualization using SceneKit:
- Point cloud representation of OKLCH color space
- Cylindrical coordinate mapping
- Interactive camera controls
- Real-time color marker
- Axis labels and guides

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

This macOS app now has feature parity with the web-based OKLCH picker at [oklch.com](https://oklch.com):

**Implemented:**
- ✅ OKLCH color space support
- ✅ Interactive sliders
- ✅ 2D color charts (L-C, C-H, L-H planes)
- ✅ 3D color space visualization
- ✅ Multiple output formats
- ✅ Color input parsing
- ✅ Gamut detection
- ✅ Alpha channel support
- ✅ Random color generation

**Advantages over Web Version:**
- ✨ Native macOS performance and integration
- ✨ SceneKit 3D rendering (vs Three.js)
- ✨ Direct macOS color picker integration
- ✨ Offline functionality
- ✨ No browser dependency

**Technical Differences:**
- Native Swift instead of JavaScript
- SceneKit instead of Three.js for 3D
- Canvas rendering instead of Web Workers for 2D charts
- SwiftUI instead of custom web components

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
