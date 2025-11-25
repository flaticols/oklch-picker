// swift-tools-version: 5.9
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
