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
        .package(url: "https://github.com/skiptools/swift-android-native.git", from: "1.5.1"),
    ],
    targets: [
        .target(
            name: "ManiLogger",
            dependencies: [
                .product(name: "ManiSwiftUIComponents", package: "ManiSwiftUIComponents"),
                // Supplies the `SwiftUI` module on Android (see skip-fuse-ui's `SwiftUI` shim target).
                .product(name: "SkipFuseUI", package: "skip-fuse-ui", condition: .when(platforms: [.android])),
                // `Logger` that writes to logcat, so Android gets console output like `os.Logger` on Apple platforms.
                .product(name: "AndroidLogging", package: "swift-android-native", condition: .when(platforms: [.android]))
            ]
        ),
        .testTarget(
            name: "ManiLoggerTests",
            dependencies: ["ManiLogger"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
