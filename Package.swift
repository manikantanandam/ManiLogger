// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ManiLogger",
    platforms: [
        .iOS(.v17), .macOS(.v14)
    ],
    products: [
        .library(
            name: "ManiLogger",
            targets: ["ManiLogger"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/manikantanandam/ManiSwiftUIComponents.git", branch: "feature/android-support"),  // TEMPORARY: restore `from: "1.2.0"` after release
        .package(url: "https://github.com/skiptools/skip-fuse-ui.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "ManiLogger",
            dependencies: [
                .product(name: "ManiSwiftUIComponents", package: "ManiSwiftUIComponents"),
                // Supplies the `SwiftUI` module on Android (see skip-fuse-ui's `SwiftUI` shim target).
                .product(name: "SkipFuseUI", package: "skip-fuse-ui", condition: .when(platforms: [.android]))
            ]
        ),
        .testTarget(
            name: "ManiLoggerTests",
            dependencies: ["ManiLogger"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
