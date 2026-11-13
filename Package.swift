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
        .package(url: "https://github.com/manikantanandam/ManiSwiftUIComponents.git", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "ManiLogger",
            dependencies: [
                .product(name: "ManiSwiftUIComponents", package: "ManiSwiftUIComponents")
            ]
        ),
        .testTarget(
            name: "ManiLoggerTests",
            dependencies: ["ManiLogger"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
