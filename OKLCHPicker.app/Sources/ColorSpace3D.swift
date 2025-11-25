import SwiftUI
import SceneKit

/// 3D OKLCH Color Space Visualization
struct ColorSpace3DView: View {
    @ObservedObject var viewModel: ColorPickerViewModel
    @State private var scene: SCNScene?
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 12) {
            Text("3D Color Space")
                .font(.headline)

            ZStack {
                if let scene = scene {
                    SceneView(
                        scene: scene,
                        options: [.allowsCameraControl, .autoenablesDefaultLighting]
                    )
                    .frame(height: 400)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                } else if isLoading {
                    ZStack {
                        Rectangle()
                            .fill(Color.black.opacity(0.05))
                            .frame(height: 400)
                            .cornerRadius(12)

                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Generating 3D color space...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Controls
            HStack {
                Text("Rotate: Drag • Zoom: Scroll")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Reset Camera") {
                    resetCamera()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .onAppear {
            generateScene()
        }
        .onChange(of: viewModel.oklchColor) { _, _ in
            updateCurrentColorMarker()
        }
    }

    // MARK: - Scene Generation

    private func generateScene() {
        isLoading = true

        Task.detached(priority: .userInitiated) {
            let newScene = await create3DColorSpace()

            await MainActor.run {
                scene = newScene
                isLoading = false
            }
        }
    }

    private func create3DColorSpace() async -> SCNScene {
        let scene = SCNScene()

        // Create camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)
        scene.rootNode.addChildNode(cameraNode)

        // Create ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 500
        scene.rootNode.addChildNode(ambientLight)

        // Create color space geometry
        let colorSpaceNode = await createColorSpaceGeometry()
        scene.rootNode.addChildNode(colorSpaceNode)

        // Create axes
        let axesNode = createAxes()
        scene.rootNode.addChildNode(axesNode)

        // Create current color marker
        let markerNode = createCurrentColorMarker()
        markerNode.name = "currentColorMarker"
        scene.rootNode.addChildNode(markerNode)

        return scene
    }

    private func createColorSpaceGeometry() async -> SCNNode {
        let parentNode = SCNNode()

        // Sample the color space with points
        let lightnessSteps = 15
        let chromaSteps = 10
        let hueSteps = 36

        let maxChroma = 0.4

        for lIndex in 0..<lightnessSteps {
            for cIndex in 0..<chromaSteps {
                for hIndex in 0..<hueSteps {
                    let l = Double(lIndex) / Double(lightnessSteps - 1)
                    let c = (Double(cIndex) / Double(chromaSteps - 1)) * maxChroma
                    let h = (Double(hIndex) / Double(hueSteps)) * 360.0

                    let oklch = OKLCHColor(lightness: l, chroma: c, hue: h, alpha: 1.0)

                    // Only show colors in sRGB gamut
                    guard ColorConverter.isInSRGBGamut(oklch) else { continue }

                    let rgb = ColorConverter.oklchToRGB(oklch)
                    let nsColor = ColorConverter.oklchToNSColor(oklch)

                    // Convert OKLCH to 3D position
                    // Use cylindrical coordinates
                    let x = c * cos(h * .pi / 180.0)
                    let y = l - 0.5 // Center around 0
                    let z = c * sin(h * .pi / 180.0)

                    // Create a small sphere for each color point
                    let sphere = SCNSphere(radius: 0.01)
                    sphere.firstMaterial?.diffuse.contents = nsColor
                    sphere.firstMaterial?.emission.contents = nsColor
                    sphere.firstMaterial?.lightingModel = .constant

                    let node = SCNNode(geometry: sphere)
                    node.position = SCNVector3(x: Float(x), y: Float(y), z: Float(z))

                    parentNode.addChildNode(node)
                }
            }
        }

        return parentNode
    }

    private func createAxes() -> SCNNode {
        let axesNode = SCNNode()

        // Helper to create an axis line
        func createAxis(from start: SCNVector3, to end: SCNVector3, color: NSColor) -> SCNNode {
            let vector = SCNVector3(
                x: end.x - start.x,
                y: end.y - start.y,
                z: end.z - start.z
            )
            let length = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)

            let cylinder = SCNCylinder(radius: 0.002, height: CGFloat(length))
            cylinder.firstMaterial?.diffuse.contents = color
            cylinder.firstMaterial?.lightingModel = .constant

            let node = SCNNode(geometry: cylinder)

            // Position and orient the cylinder
            node.position = SCNVector3(
                x: (start.x + end.x) / 2,
                y: (start.y + end.y) / 2,
                z: (start.z + end.z) / 2
            )

            // Rotate to align with the vector
            let zAxis = SCNVector3(0, 1, 0)
            let angle = acos((vector.y) / length)
            let rotationAxis = SCNVector3(
                x: -vector.z,
                y: 0,
                z: vector.x
            )

            if length > 0.001 {
                node.rotation = SCNVector4(
                    x: rotationAxis.x,
                    y: rotationAxis.y,
                    z: rotationAxis.z,
                    w: angle
                )
            }

            return node
        }

        // L axis (vertical, gray)
        let lAxis = createAxis(
            from: SCNVector3(0, -0.5, 0),
            to: SCNVector3(0, 0.5, 0),
            color: .gray
        )
        axesNode.addChildNode(lAxis)

        // C axis (radial, from center)
        let cAxis = createAxis(
            from: SCNVector3(0, 0, 0),
            to: SCNVector3(0.4, 0, 0),
            color: .blue
        )
        axesNode.addChildNode(cAxis)

        // Add labels
        func createLabel(text: String, position: SCNVector3) -> SCNNode {
            let textGeometry = SCNText(string: text, extrusionDepth: 0)
            textGeometry.font = NSFont.systemFont(ofSize: 0.05)
            textGeometry.firstMaterial?.diffuse.contents = NSColor.white
            textGeometry.firstMaterial?.lightingModel = .constant

            let textNode = SCNNode(geometry: textGeometry)
            textNode.position = position
            textNode.scale = SCNVector3(0.01, 0.01, 0.01)

            return textNode
        }

        axesNode.addChildNode(createLabel(text: "L", position: SCNVector3(0, 0.55, 0)))
        axesNode.addChildNode(createLabel(text: "C", position: SCNVector3(0.45, 0, 0)))

        return axesNode
    }

    private func createCurrentColorMarker() -> SCNNode {
        let sphere = SCNSphere(radius: 0.03)
        sphere.firstMaterial?.diffuse.contents = viewModel.currentColor
        sphere.firstMaterial?.emission.contents = viewModel.currentColor

        // Add a white ring around it
        let torus = SCNTorus(ringRadius: 0.04, pipeRadius: 0.005)
        torus.firstMaterial?.diffuse.contents = NSColor.white
        torus.firstMaterial?.lightingModel = .constant

        let markerNode = SCNNode(geometry: sphere)
        let ringNode = SCNNode(geometry: torus)
        markerNode.addChildNode(ringNode)

        updateMarkerPosition(markerNode)

        return markerNode
    }

    private func updateMarkerPosition(_ node: SCNNode) {
        let oklch = viewModel.oklchColor

        let x = oklch.chroma * cos(oklch.hue * .pi / 180.0)
        let y = oklch.lightness - 0.5
        let z = oklch.chroma * sin(oklch.hue * .pi / 180.0)

        node.position = SCNVector3(x: Float(x), y: Float(y), z: Float(z))
    }

    // MARK: - Update Current Color

    private func updateCurrentColorMarker() {
        guard let scene = scene,
              let markerNode = scene.rootNode.childNode(withName: "currentColorMarker", recursively: false) else {
            return
        }

        // Update color
        if let sphere = markerNode.geometry as? SCNSphere {
            sphere.firstMaterial?.diffuse.contents = viewModel.currentColor
            sphere.firstMaterial?.emission.contents = viewModel.currentColor
        }

        // Update position
        updateMarkerPosition(markerNode)
    }

    // MARK: - Camera Control

    private func resetCamera() {
        guard let scene = scene,
              let cameraNode = scene.rootNode.childNodes.first(where: { $0.camera != nil }) else {
            return
        }

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5

        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)
        cameraNode.eulerAngles = SCNVector3(0, 0, 0)

        SCNTransaction.commit()
    }
}

// MARK: - SceneView Wrapper

#if os(macOS)
struct SceneView: NSViewRepresentable {
    let scene: SCNScene
    let options: SCNView.Options

    func makeNSView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = scene
        scnView.allowsCameraControl = options.contains(.allowsCameraControl)
        scnView.autoenablesDefaultLighting = options.contains(.autoenablesDefaultLighting)
        scnView.backgroundColor = NSColor(white: 0.1, alpha: 1.0)
        return scnView
    }

    func updateNSView(_ nsView: SCNView, context: Context) {
        nsView.scene = scene
    }
}

extension SCNView {
    struct Options: OptionSet {
        let rawValue: Int

        static let allowsCameraControl = Options(rawValue: 1 << 0)
        static let autoenablesDefaultLighting = Options(rawValue: 1 << 1)
    }
}
#endif
