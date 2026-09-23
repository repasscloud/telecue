// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "telecue",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "TeleCue", targets: ["TeleCue"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.9.0")
    ],
    targets: [
        .executableTarget(
            name: "TeleCue",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ],
            path: "Sources/TeleCue"
        ),
        .testTarget(
            name: "TeleCueTests",
            dependencies: ["TeleCue"],
            path: "Tests/TeleCueTests"
        )
    ],
    swiftLanguageModes: [.v6]
)

