// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "GLibObject",
    products: [
        .library(
            name: "GLibObject",
            targets: ["GLibObject"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/rpinz/SwiftGLib",
            .branch("master"))
    ],
    targets: [
        .target(
            name: "GLibObject",
            dependencies: ["GLib"],
            path: "Sources"),
        .testTarget(
            name: "GLibObjectTests",
            dependencies: ["GLibObject"])
    ],
    swiftLanguageVersions: [4]
)
