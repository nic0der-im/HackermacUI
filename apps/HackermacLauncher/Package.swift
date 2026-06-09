// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HackermacLauncher",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "HackermacLauncher", targets: ["HackermacLauncher"])
    ],
    targets: [
        .executableTarget(name: "HackermacLauncher")
    ]
)
