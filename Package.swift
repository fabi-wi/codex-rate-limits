// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CodexRateLimits",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CodexRateLimitsApp", targets: ["CodexRateLimitsApp"]),
        .library(name: "CodexRateLimitsCore", targets: ["CodexRateLimitsCore"])
    ],
    targets: [
        .target(
            name: "CodexRateLimitsCore",
            path: "Sources/CodexRateLimitsCore"
        ),
        .executableTarget(
            name: "CodexRateLimitsApp",
            dependencies: ["CodexRateLimitsCore"],
            path: "App",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CodexRateLimitsCoreTests",
            dependencies: ["CodexRateLimitsCore"],
            path: "Tests/CodexRateLimitsCoreTests"
        )
    ]
)
