import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ColorPickerViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Main Picker Tab
            PickerView(viewModel: viewModel)
                .tabItem {
                    Label("Picker", systemImage: "paintpalette")
                }
                .tag(0)

            // 2D Charts Tab
            ColorChartsView(viewModel: viewModel)
                .tabItem {
                    Label("2D Charts", systemImage: "square.grid.2x2")
                }
                .tag(1)

            // 3D Visualization Tab
            ColorSpace3DView(viewModel: viewModel)
                .tabItem {
                    Label("3D View", systemImage: "cube")
                }
                .tag(2)
        }
        .frame(minWidth: 600, minHeight: 750)
    }
}

// MARK: - Main Picker View

struct PickerView: View {
    @ObservedObject var viewModel: ColorPickerViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Title
                Text("OKLCH Color Picker")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top)

                // Color Preview
                ColorPreviewView(color: Color(viewModel.currentColor))
                    .frame(height: 150)
                    .padding(.horizontal)

                // Gamut Status
                HStack {
                    Image(systemName: viewModel.isInSRGBGamut ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(Color(viewModel.gamutStatusColor))
                    Text(viewModel.gamutStatus)
                        .font(.caption)
                        .foregroundColor(Color(viewModel.gamutStatusColor))
                }
                .padding(.horizontal)

                // Sliders
                VStack(spacing: 15) {
                    SliderView(
                        label: "Lightness (L)",
                        value: $viewModel.lightness,
                        range: 0...1,
                        color: .gray
                    )

                    SliderView(
                        label: "Chroma (C)",
                        value: $viewModel.chroma,
                        range: 0...viewModel.maxChroma,
                        color: .blue
                    )

                    HueSliderView(value: $viewModel.hue)

                    SliderView(
                        label: "Alpha",
                        value: $viewModel.alpha,
                        range: 0...1,
                        color: .purple
                    )
                }
                .padding(.horizontal)

                Divider()

                // Format Selection and Output
                VStack(spacing: 10) {
                    Picker("Format", selection: $viewModel.selectedFormat) {
                        ForEach(ColorFormat.allCases, id: \.self) { format in
                            Text(format.description).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.selectedFormat) { _, newValue in
                        viewModel.updateFormat(newValue)
                    }

                    HStack {
                        Text(viewModel.formattedColor)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)

                        Button(action: viewModel.copyToClipboard) {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        .help("Copy to clipboard")
                    }
                }
                .padding(.horizontal)

                Divider()

                // Input Section
                VStack(spacing: 8) {
                    Text("Import Color")
                        .font(.headline)

                    HStack {
                        TextField("Enter color (hex, rgb, oklch...)", text: $viewModel.inputText)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                viewModel.parseInput()
                            }

                        Button("Parse") {
                            viewModel.parseInput()
                        }
                        .buttonStyle(.bordered)
                    }

                    if let error = viewModel.inputError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)

                // Action Buttons
                HStack(spacing: 15) {
                    Button("Random Color") {
                        viewModel.randomColor()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("macOS Color Picker") {
                        NSColorPanel.shared.orderFront(nil)
                        viewModel.importFromColorPanel()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.bottom)
            }
            .padding()
        }
    }
}

// MARK: - Color Preview View

struct ColorPreviewView: View {
    let color: Color

    var body: some View {
        ZStack {
            // Checkerboard background for transparency
            CheckerboardView()

            // Color
            RoundedRectangle(cornerRadius: 12)
                .fill(color)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .shadow(radius: 5)
    }
}

// MARK: - Checkerboard Background

struct CheckerboardView: View {
    let size: CGFloat = 10

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let rows = Int(geometry.size.height / size) + 1
                let cols = Int(geometry.size.width / size) + 1

                for row in 0..<rows {
                    for col in 0..<cols {
                        if (row + col) % 2 == 0 {
                            let rect = CGRect(
                                x: CGFloat(col) * size,
                                y: CGFloat(row) * size,
                                width: size,
                                height: size
                            )
                            path.addRect(rect)
                        }
                    }
                }
            }
            .fill(Color.gray.opacity(0.2))
        }
    }
}

// MARK: - Slider View

struct SliderView: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.3f", value))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Slider(value: $value, in: range)
                .tint(color)
        }
    }
}

// MARK: - Hue Slider View

struct HueSliderView: View {
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Hue (H)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(value))°")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            ZStack(alignment: .leading) {
                // Rainbow gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hue: 0/360, saturation: 1, brightness: 1),
                        Color(hue: 60/360, saturation: 1, brightness: 1),
                        Color(hue: 120/360, saturation: 1, brightness: 1),
                        Color(hue: 180/360, saturation: 1, brightness: 1),
                        Color(hue: 240/360, saturation: 1, brightness: 1),
                        Color(hue: 300/360, saturation: 1, brightness: 1),
                        Color(hue: 360/360, saturation: 1, brightness: 1)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 20)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

                Slider(value: $value, in: 0...360)
                    .opacity(0.02) // Nearly invisible but still interactive
            }
        }
    }
}

#Preview {
    ContentView()
}
