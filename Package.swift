// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "splashaudio",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit", exact: "0.13.1"),
    ],
    targets: [
        .executableTarget(
            name: "splashaudio",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit"),
            ],
            path: "Sources/splashaudio"
        ),
    ]
)
