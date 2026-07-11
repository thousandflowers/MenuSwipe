// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MenuSwipe",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MenuSwipe",
            path: "Sources/MenuSwipe"
        )
    ]
)
