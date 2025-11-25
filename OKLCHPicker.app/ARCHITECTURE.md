# OKLCH Picker - Architecture Documentation

## Overview

This macOS application is a native Swift/SwiftUI implementation of an OKLCH color picker, inspired by the web-based picker at [oklch.com](https://oklch.com). It provides a clean, native macOS interface for working with colors in the OKLCH color space.

## Project Structure

```
OKLCHPicker.app/
├── Package.swift                    # Swift Package Manager configuration
├── README.md                        # User documentation
├── ARCHITECTURE.md                  # This file
├── build.sh                         # Build script
├── .gitignore                       # Git ignore rules
└── Sources/
    ├── main.swift                   # App entry point
    ├── ContentView.swift            # Main UI
    ├── ColorPickerViewModel.swift   # State management
    ├── ColorConversion.swift        # Color space conversions
    └── ColorFormats.swift           # Formatting and parsing
```

## Component Details

### 1. main.swift
**Purpose**: Application entry point

**Key Elements**:
- `@main` attribute marking the app entry
- `OKLCHPickerApp` struct conforming to `App` protocol
- Window configuration (hidden title bar, fixed size)
- Command customization (disable New Window)

**Dependencies**: SwiftUI

---

### 2. ContentView.swift
**Purpose**: Main user interface using SwiftUI

**Key Components**:
- `ContentView`: Main view container
- `ColorPreviewView`: Large color swatch with transparency support
- `CheckerboardView`: Background pattern for transparency visualization
- `SliderView`: Generic slider with label and value display
- `HueSliderView`: Specialized hue slider with rainbow gradient

**UI Layout**:
```
┌─────────────────────────────┐
│ Title: OKLCH Color Picker   │
├─────────────────────────────┤
│    [Color Preview Box]       │
│    ✓ Gamut Status           │
├─────────────────────────────┤
│ L: ███████████░░ 0.700      │
│ C: ████░░░░░░░░░ 0.150      │
│ H: [Rainbow]════ 180°       │
│ A: ███████████░░ 1.000      │
├─────────────────────────────┤
│ [Format: OKLCH|HEX|RGB...] │
│ oklch(0.7 0.15 180) [Copy] │
├─────────────────────────────┤
│ Import Color:                │
│ [Text Input] [Parse]        │
├─────────────────────────────┤
│ [Random] [macOS Picker]     │
└─────────────────────────────┘
```

**Dependencies**: SwiftUI, ColorPickerViewModel

---

### 3. ColorPickerViewModel.swift
**Purpose**: State management and business logic

**Key Properties**:
- `@Published lightness`: L component (0-1)
- `@Published chroma`: C component (0-0.4)
- `@Published hue`: H component (0-360)
- `@Published alpha`: Alpha channel (0-1)
- `@Published currentColor`: Computed NSColor
- `@Published selectedFormat`: Output format
- `@Published formattedColor`: Formatted string
- `@Published isInSRGBGamut`: Gamut check result

**Key Methods**:
- `updateColor()`: Recompute color and formats
- `updateFormat()`: Change output format
- `copyToClipboard()`: Copy color to pasteboard
- `randomColor()`: Generate random values
- `parseInput()`: Parse color string input
- `importFromColorPanel()`: Import from NSColorPanel

**Design Pattern**: MVVM (Model-View-ViewModel)

**Dependencies**: Foundation, AppKit, Combine

---

### 4. ColorConversion.swift
**Purpose**: OKLCH ↔ RGB color space conversions

**Data Structures**:
- `OKLCHColor`: L, C, H, Alpha
- `RGBColor`: R, G, B, Alpha
- `OklabColor`: L, a, b, Alpha (intermediate)

**Conversion Pipeline**:

#### OKLCH → RGB
```
OKLCH → Oklab → Linear RGB → sRGB
  ↓       ↓         ↓          ↓
(L,C,H) (L,a,b)  (R,G,B)   (R,G,B)
         polar    linear    gamma
```

#### RGB → OKLCH
```
sRGB → Linear RGB → Oklab → OKLCH
  ↓        ↓          ↓       ↓
(R,G,B) (R,G,B)   (L,a,b)  (L,C,H)
gamma   linear     cart     polar
```

**Mathematical Transformations**:

1. **OKLCH to Oklab** (Polar to Cartesian):
   ```
   a = C × cos(H)
   b = C × sin(H)
   ```

2. **Oklab to Linear RGB** (Matrix transform):
   ```
   [l]   [L]
   [m] = M × [a]
   [s]   [b]

   [R]       [l³]
   [G] = M⁻¹ [m³]
   [B]       [s³]
   ```

3. **Linear RGB to sRGB** (Gamma correction):
   ```
   if C ≤ 0.0031308:
       sRGB = 12.92 × C
   else:
       sRGB = 1.055 × C^(1/2.4) - 0.055
   ```

**Key Methods**:
- `oklchToRGB()`: Full forward conversion
- `rgbToOKLCH()`: Full reverse conversion
- `oklchToNSColor()`: Convert to NSColor
- `nsColorToOKLCH()`: Convert from NSColor
- `isInSRGBGamut()`: Check gamut
- `round()`: Precision control

**Dependencies**: Foundation, AppKit

---

### 5. ColorFormats.swift
**Purpose**: Format colors for output and parse input

**Supported Formats**:
1. **OKLCH**: `oklch(L C H / A%)`
2. **HEX**: `#RRGGBB` or `#RRGGBBAA`
3. **RGB**: `rgb(R, G, B)` or `rgba(R, G, B, A)`
4. **HSL**: `hsl(H, S%, L%)` or `hsla(H, S%, L%, A)`
5. **Oklab**: `oklab(L a b / A)`
6. **Numbers**: `L, C, H, A`

**Key Methods**:

**Formatting**:
- `format(_:as:)`: Main formatting dispatcher
- `formatOKLCH()`: OKLCH output
- `formatHex()`: Hex output
- `formatRGB()`: RGB output
- `formatHSL()`: HSL output
- `formatOklab()`: Oklab output
- `formatNumbers()`: Raw numbers

**Parsing**:
- `parseColorString()`: Main parser
- `parseHex()`: Parse hex colors
- `parseOKLCH()`: Parse OKLCH
- `parseRGB()`: Parse RGB/RGBA
- Uses regex for pattern matching

**Helper Functions**:
- `rgbToHSL()`: RGB to HSL conversion
- `clampValue()`: Value clamping
- `extractDouble()`: Regex extraction

**Dependencies**: Foundation, AppKit

---

## Data Flow

### User Interaction Flow
```
User moves slider
    ↓
SwiftUI binding updates ViewModel property
    ↓
didSet triggers updateColor()
    ↓
OKLCHColor created
    ↓
ColorConverter.oklchToRGB()
    ↓
NSColor updated → View updates
    ↓
ColorFormatter.format() → Display updated
```

### Import Flow
```
User enters color string
    ↓
parseInput() called
    ↓
ColorFormatter.parseColorString()
    ↓
Returns OKLCHColor or nil
    ↓
If valid: Update slider values
    ↓
Normal update flow triggers
```

## Color Space Mathematics

### Why OKLCH?

**Problems with HSL/RGB**:
- Not perceptually uniform
- L=50% in HSL doesn't always look "middle lightness"
- Hue shifts when adjusting saturation (in LCH)
- Can't represent wide-gamut colors

**OKLCH Advantages**:
- Perceptually uniform: ΔE = √(ΔL² + ΔC² + ΔH²)
- Predictable lightness
- No hue shifts
- Wide gamut support
- Direct CSS support

### Oklab Specification

Based on Björn Ottosson's 2020 paper, Oklab provides:
- Better perceptual uniformity than Lab
- Simpler math than CAM16
- Good performance
- Compact representation

**Key matrices** (hard-coded in ColorConversion.swift):
```
M1 = LMS from Linear RGB
M2 = Oklab from LMS^(1/3)
```

### Gamut Handling

**sRGB Gamut Check**:
```swift
func isInSRGBGamut(_ oklch: OKLCHColor) -> Bool {
    let rgb = oklchToRGB(oklch)
    return rgb.r ∈ [0, 1] &&
           rgb.g ∈ [0, 1] &&
           rgb.b ∈ [0, 1]
}
```

**Out-of-Gamut Colors**:
- Colors with high chroma may exceed sRGB
- App clamps RGB values for display
- Warning shown to user
- Future: Gamut mapping algorithms

## Build System

### Swift Package Manager

**Advantages**:
- Native Swift tooling
- Cross-platform potential
- Lightweight (no Xcode project files)
- Easy CI/CD integration

**Configuration** (Package.swift):
```swift
platforms: [.macOS(.v13)]  // Requires macOS 13+
products: [.executable]     // Standalone app
targets: [.executableTarget] // Single target
```

### Building

**Debug Build**:
```bash
swift build
swift run OKLCHPicker
```

**Release Build**:
```bash
swift build -c release
./.build/release/OKLCHPicker
```

**With Xcode**:
```bash
open Package.swift
# Then: Cmd+R to run
```

## Future Enhancements

### Potential Features
1. **2D Color Charts**: Like web version, clickable L-C, C-H, H-L planes
2. **3D Visualization**: SceneKit or RealityKit 3D color space
3. **Color Palettes**: Save/manage color collections
4. **Accessibility**: Contrast checking, WCAG compliance
5. **P3 and Rec2020**: Wide gamut support
6. **Color Blindness Simulation**: Preview for different types
7. **Gradient Generator**: Create smooth OKLCH gradients
8. **Export Presets**: Export for different platforms/tools

### Technical Improvements
1. **Better Gamut Mapping**: Perceptual gamut compression
2. **Color Harmony**: Show complementary, analogous colors
3. **History**: Undo/redo color changes
4. **Keyboard Shortcuts**: Fine-tune with arrow keys
5. **Touch Bar Support**: Quick access to sliders
6. **SwiftUI Previews**: Better development experience

## Testing Strategy

### Unit Tests (Future)
- Color conversion accuracy
- Format parsing
- Round-trip conversions (OKLCH → RGB → OKLCH)
- Edge cases (black, white, grays, out-of-gamut)

### Integration Tests
- ViewModel logic
- Clipboard operations
- Format switching

### UI Tests
- Slider interactions
- Button actions
- Color picker import

## Performance Considerations

### Current Performance
- Real-time color updates (60fps)
- Immediate slider response
- O(1) color conversions

### Optimization Opportunities
1. Cache formatted strings
2. Debounce slider updates
3. Lazy evaluation for non-visible formats
4. Parallel format generation

## Dependencies

### Standard Library
- Foundation: Core types, parsing
- AppKit: NSColor, NSPasteboard, NSColorPanel
- SwiftUI: UI framework
- Combine: Reactive updates

### No External Dependencies
- All color math implemented from scratch
- No culori.js equivalent needed
- Pure Swift implementation

## Comparison with Web Version

### Feature Parity

| Feature | Web | macOS | Notes |
|---------|-----|-------|-------|
| OKLCH Sliders | ✅ | ✅ | Core functionality |
| 2D Color Charts | ✅ | ❌ | Future enhancement |
| 3D Model | ✅ | ❌ | Optional in web too |
| Format Output | ✅ | ✅ | 6 formats supported |
| Gamut Detection | ✅ | ✅ | sRGB only currently |
| Color Import | ✅ | ✅ | Multiple formats |
| Copy to Clipboard | ✅ | ✅ | Native integration |
| URL State | ✅ | ❌ | Not applicable |
| P3/Rec2020 | ✅ | ❌ | Future enhancement |

### Architectural Differences

**Web Version**:
- Uses culori.js for conversions
- Three.js for 3D visualization
- Canvas for 2D charts
- Web Workers for rendering
- Nanostores for state
- Vite for bundling

**macOS Version**:
- Native Swift math
- SwiftUI for UI
- No 2D/3D charts (yet)
- Single-threaded (fast enough)
- @Published for state
- Swift Package Manager

## Credits and References

- **Oklab**: Björn Ottosson (https://bottosson.github.io/posts/oklab/)
- **Web Version**: Evil Martians (https://oklch.com)
- **CSS Color 4**: W3C Specification
- **OKLCH Article**: https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl
