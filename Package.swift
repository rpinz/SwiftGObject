import PackageDescription

let package = Package(
    name: "GLibObject",
    dependencies: [
        .Package(url: "https://github.com/rpinz/SwiftGLib", majorVersion: 2)
    ],
    swiftLanguageVersions: [3, 4]
)
