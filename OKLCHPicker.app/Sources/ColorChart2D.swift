import SwiftUI

/// Represents which 2D plane to display
enum ChartPlane: String, CaseIterable {
    case chromaHue = "C-H"      // Chroma vs Hue (fixed Lightness)
    case lightnessChroma = "L-C" // Lightness vs Chroma (fixed Hue)
    case lightnessHue = "L-H"    // Lightness vs Hue (fixed Chroma)

    var description: String {
        switch self {
        case .chromaHue:
            return "Chroma × Hue"
        case .lightnessChroma:
            return "Lightness × Chroma"
        case .lightnessHue:
            return "Lightness × Hue"
        }
    }
}

/// 2D Color Chart View using Canvas
struct ColorChart2DView: View {
    let plane: ChartPlane
    let fixedValue: Double
    let currentL: Double
    let currentC: Double
    let currentH: Double
    let maxChroma: Double
    let onColorSelected: (Double, Double, Double) -> Void

    @State private var renderedImage: Image?
    @State private var isRendering = false
    @State private var chartSize: CGSize = .zero
    @State private var lastRenderedFixedValue: Double?

    // Resolution for color sampling (optimized for performance)
    private let resolution: Int = 150

    var body: some View {
        VStack(spacing: 8) {
            // Chart title
            HStack {
                Text(plane.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(fixedValueText)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            // Chart canvas
            GeometryReader { geometry in
                ZStack {
                    // Background
                    Rectangle()
                        .fill(Color.black.opacity(0.05))

                    // Rendered color chart
                    if let image = renderedImage {
                        image
                            .resizable()
                            .interpolation(.none)
                    } else if isRendering {
                        ProgressView()
                    }

                    // Current color indicator
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .background(Circle().stroke(Color.black, lineWidth: 4))
                        .frame(width: 16, height: 16)
                        .position(currentPosition(in: geometry.size))
                }
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleInteraction(at: value.location, in: geometry.size)
                        }
                )
                .onAppear {
                    chartSize = geometry.size
                    renderChart(size: geometry.size)
                }
                .onChange(of: geometry.size) { _, newSize in
                    chartSize = newSize
                    renderChart(size: newSize)
                }
                .onChange(of: fixedValue) { _, newValue in
                    // Only re-render if the change is significant (debouncing)
                    if shouldRerender(newValue) {
                        renderChart(size: geometry.size)
                        lastRenderedFixedValue = newValue
                    }
                }
            }
            .frame(height: 250)
        }
    }

    // MARK: - Fixed Value Text

    private var fixedValueText: String {
        switch plane {
        case .chromaHue:
            return "L: \(String(format: "%.3f", fixedValue))"
        case .lightnessChroma:
            return "H: \(String(format: "%.0f", fixedValue))°"
        case .lightnessHue:
            return "C: \(String(format: "%.3f", fixedValue))"
        }
    }

    // MARK: - Performance Optimization

    private func shouldRerender(_ newValue: Double) -> Bool {
        guard let lastValue = lastRenderedFixedValue else { return true }

        // Define threshold based on plane type to avoid excessive re-renders
        let threshold: Double
        switch plane {
        case .chromaHue:
            threshold = 0.01  // Lightness change threshold
        case .lightnessChroma:
            threshold = 5.0   // Hue change threshold (degrees)
        case .lightnessHue:
            threshold = 0.01  // Chroma change threshold
        }

        return abs(newValue - lastValue) >= threshold
    }

    // MARK: - Current Position

    private func currentPosition(in size: CGSize) -> CGPoint {
        switch plane {
        case .chromaHue:
            // X = Hue (0-360), Y = Chroma (0-maxChroma)
            let x = (currentH / 360.0) * size.width
            let y = size.height - (currentC / maxChroma) * size.height
            return CGPoint(x: x, y: y)
        case .lightnessChroma:
            // X = Lightness (0-1), Y = Chroma (0-maxChroma)
            let x = currentL * size.width
            let y = size.height - (currentC / maxChroma) * size.height
            return CGPoint(x: x, y: y)
        case .lightnessHue:
            // X = Hue (0-360), Y = Lightness (0-1)
            let x = (currentH / 360.0) * size.width
            let y = size.height - currentL * size.height
            return CGPoint(x: x, y: y)
        }
    }

    // MARK: - Interaction Handling

    private func handleInteraction(at location: CGPoint, in size: CGSize) {
        let x = max(0, min(location.x, size.width))
        let y = max(0, min(location.y, size.height))

        switch plane {
        case .chromaHue:
            let h = (x / size.width) * 360.0
            let c = ((size.height - y) / size.height) * maxChroma
            onColorSelected(fixedValue, c, h)
        case .lightnessChroma:
            let l = x / size.width
            let c = ((size.height - y) / size.height) * maxChroma
            onColorSelected(l, c, fixedValue)
        case .lightnessHue:
            let h = (x / size.width) * 360.0
            let l = (size.height - y) / size.height
            onColorSelected(l, fixedValue, h)
        }
    }

    // MARK: - Chart Rendering

    private func renderChart(size: CGSize) {
        guard size.width > 0 && size.height > 0 else { return }

        isRendering = true

        Task.detached(priority: .userInitiated) {
            let image = await generateChartImage(size: size)

            await MainActor.run {
                renderedImage = image
                isRendering = false
            }
        }
    }

    private func generateChartImage(size: CGSize) async -> Image {
        let width = Int(size.width)
        let height = Int(size.height)

        // Create bitmap
        var pixels = [UInt8](repeating: 0, count: width * height * 4)

        // Sample colors at lower resolution for performance
        let stepX = max(1, width / resolution)
        let stepY = max(1, height / resolution)

        for py in stride(from: 0, to: height, by: stepY) {
            for px in stride(from: 0, to: width, by: stepX) {
                let color = getColorAt(x: px, y: py, width: width, height: height)

                // Fill the step area with the same color
                for dy in 0..<stepY {
                    for dx in 0..<stepX {
                        let actualX = px + dx
                        let actualY = py + dy

                        if actualX < width && actualY < height {
                            let offset = (actualY * width + actualX) * 4
                            pixels[offset] = color.r
                            pixels[offset + 1] = color.g
                            pixels[offset + 2] = color.b
                            pixels[offset + 3] = color.a
                        }
                    }
                }
            }
        }

        // Create CGImage
        guard let cgImage = createCGImage(from: pixels, width: width, height: height) else {
            return Image(systemName: "exclamationmark.triangle")
        }

        return Image(decorative: cgImage, scale: 1.0)
    }

    private func getColorAt(x: Int, y: Int, width: Int, height: Int) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        let l: Double
        let c: Double
        let h: Double

        switch plane {
        case .chromaHue:
            h = (Double(x) / Double(width)) * 360.0
            c = (Double(height - y) / Double(height)) * maxChroma
            l = fixedValue
        case .lightnessChroma:
            l = Double(x) / Double(width)
            c = (Double(height - y) / Double(height)) * maxChroma
            h = fixedValue
        case .lightnessHue:
            h = (Double(x) / Double(width)) * 360.0
            l = (Double(height - y) / Double(height))
            c = fixedValue
        }

        let oklch = OKLCHColor(lightness: l, chroma: c, hue: h, alpha: 1.0)
        let rgb = ColorConverter.oklchToRGB(oklch)

        // Check if in gamut
        let inGamut = ColorConverter.isInSRGBGamut(oklch)

        if inGamut {
            return (
                r: UInt8(clamp(rgb.r) * 255),
                g: UInt8(clamp(rgb.g) * 255),
                b: UInt8(clamp(rgb.b) * 255),
                a: 255
            )
        } else {
            // Out of gamut - show clamped color with reduced opacity
            return (
                r: UInt8(clamp(rgb.r) * 255),
                g: UInt8(clamp(rgb.g) * 255),
                b: UInt8(clamp(rgb.b) * 255),
                a: 80 // Dimmed to indicate out of gamut
            )
        }
    }

    private func clamp(_ value: Double) -> Double {
        return max(0.0, min(1.0, value))
    }

    private func createCGImage(from pixels: [UInt8], width: Int, height: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let providerRef = CGDataProvider(data: Data(pixels) as CFData) else {
            return nil
        }

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: providerRef,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}

// MARK: - Color Charts Container

struct ColorChartsView: View {
    @ObservedObject var viewModel: ColorPickerViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("2D Color Charts")
                .font(.headline)

            TabView {
                ColorChart2DView(
                    plane: .lightnessChroma,
                    fixedValue: viewModel.hue,
                    currentL: viewModel.lightness,
                    currentC: viewModel.chroma,
                    currentH: viewModel.hue,
                    maxChroma: viewModel.maxChroma,
                    onColorSelected: { l, c, _ in
                        viewModel.lightness = l
                        viewModel.chroma = c
                    }
                )
                .tabItem {
                    Label("L-C", systemImage: "square.grid.2x2")
                }

                ColorChart2DView(
                    plane: .chromaHue,
                    fixedValue: viewModel.lightness,
                    currentL: viewModel.lightness,
                    currentC: viewModel.chroma,
                    currentH: viewModel.hue,
                    maxChroma: viewModel.maxChroma,
                    onColorSelected: { _, c, h in
                        viewModel.chroma = c
                        viewModel.hue = h
                    }
                )
                .tabItem {
                    Label("C-H", systemImage: "circle.grid.2x2")
                }

                ColorChart2DView(
                    plane: .lightnessHue,
                    fixedValue: viewModel.chroma,
                    currentL: viewModel.lightness,
                    currentC: viewModel.chroma,
                    currentH: viewModel.hue,
                    maxChroma: viewModel.maxChroma,
                    onColorSelected: { l, _, h in
                        viewModel.lightness = l
                        viewModel.hue = h
                    }
                )
                .tabItem {
                    Label("L-H", systemImage: "circle.square")
                }
            }
            .frame(height: 300)
        }
        .padding()
    }
}
