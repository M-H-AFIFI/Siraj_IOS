// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "SirajCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SirajCore",
            targets: ["SirajCore"]
        )
    ],
    targets: [
        .target(
            name: "SirajCore",
            path: "Sources/SirajCore"
        ),
        .testTarget(
            name: "SirajCoreTests",
            dependencies: ["SirajCore"],
            path: "Tests/SirajCoreTests",
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)
