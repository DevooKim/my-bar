// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "MyBar",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "MyBar", targets: ["MyBar"])
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.0")
    ],
    targets: [
        .executableTarget(
            name: "MyBar",
            dependencies: ["HotKey"],
            path: "Sources/MyBar"
        ),
        .testTarget(
            name: "MyBarTests",
            dependencies: ["MyBar"],
            path: "Tests/MyBarTests"
        )
    ],
    swiftLanguageModes: [.v5]
)
