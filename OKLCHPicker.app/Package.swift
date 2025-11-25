// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OKLCHPicker",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "OKLCHPicker", targets: ["OKLCHPicker"])
    ],
    targets: [
        .executableTarget(
            name: "OKLCHPicker",
            path: "Sources"
        )
    ]
)
