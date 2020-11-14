// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "VisualDebugger",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
    .library(name: "VisualDebugger",
             targets: ["VisualDebugger"]),
    .executable(name: "VisualDebuggerApp",
                targets: [
                    "VisualDebuggerApp"
    ])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0")
    ],
    targets: [
        .target(name: "VisualDebuggerApp",
                dependencies: ["VisualDebugger"],
                linkerSettings: [
                    .unsafeFlags(
                        ["-sectcreate", "__TEXT", "__info_plist",  "Info.plist"]
                    )
        ]),
        .target(
            name: "VisualDebugger",
            dependencies: [.product(name: "NIO", package: "swift-nio")]
        ),
        .testTarget(
            name: "VisualDebuggerTests",
            dependencies: ["VisualDebugger"]
        ),
    ]
)
