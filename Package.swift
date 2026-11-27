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
        .package(url: "https://github.com/manikantanandam/ManiSwiftUIComponents.git", from: "1.3.0"),
        .package(url: "https://github.com/skiptools/skip.git", from: "1.9.13"),
        .package(url: "https://github.com/skiptools/skip-fuse-ui.git", from: "1.0.0"),
        .package(url: "https://github.com/skiptools/swift-android-native.git", from: "1.5.1"),
    ],
    targets: [
        .target(
            name: "ManiLogger",
            dependencies: [
                .product(name: "ManiSwiftUIComponents", package: "ManiSwiftUIComponents"),
                // Unconditional: skipstone resolves the Kotlin side's dependencies on the host, so an
                // Android-only condition leaves the generated bridge code without `skip.bridge`.
                .product(name: "SkipFuseUI", package: "skip-fuse-ui"),
                // `Logger` that writes to logcat, so Android gets console output like `os.Logger` on Apple platforms.
                .product(name: "AndroidLogging", package: "swift-android-native", condition: .when(platforms: [.android]))
            ],
            // skipstone generates the SkipUIBridging conformance the log viewer's views need to render on
            // Android (Skip Fuse); without it they render as EmptyView.
            plugins: [.plugin(name: "skipstone", package: "skip")]
        ),
        .testTarget(
            name: "ManiLoggerTests",
            dependencies: ["ManiLogger"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
