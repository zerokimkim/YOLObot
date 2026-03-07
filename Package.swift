// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YOLObot",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "YOLObot",
            path: "Sources"
        )
    ]
)
