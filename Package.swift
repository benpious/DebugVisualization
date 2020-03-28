// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VisualDebugger",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
    .library(name: "VisualDebugger",
             targets: ["VisualDebugger"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "VisualDebugger",
            dependencies: ["NIO"]),
        .testTarget(
            name: "VisualDebuggerTests",
            dependencies: ["VisualDebugger"]),
    ]
)
