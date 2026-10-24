// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WayShot",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "WayShotLib",
            targets: ["WayShot"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "WayShot",
            dependencies: [],
            path: "WayShot",
            resources: [
                .process("Resources/Presets")
            ]
        ),
        .testTarget(
            name: "WayShotTests",
            dependencies: ["WayShot"],
            path: "WayShotTests"
        ),
    ]
)
