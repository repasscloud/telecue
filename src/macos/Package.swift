// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "telecue",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .executable(name: "TeleCue", targets: ["TeleCue"]),
        .library(name: "TeleCueCore", targets: ["TeleCueCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.9.0")
    ],
    targets: [
        // Platform-neutral engine, model, parsing, rendering, and shared SwiftUI
        // controls. Must build for both macOS and iOS: no AppKit or UIKit-only code
        // outside `#if os(macOS)` shims.
        .target(
            name: "TeleCueCore",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ],
            path: "Sources/TeleCueCore"
        ),
        // The macOS app shell: floating prompter panel, menus, and AppKit views.
        .executableTarget(
            name: "TeleCue",
            dependencies: ["TeleCueCore"],
            path: "Sources/TeleCue"
        ),
        .testTarget(
            name: "TeleCueCoreTests",
            dependencies: ["TeleCueCore"],
            path: "Tests/TeleCueCoreTests"
        ),
        .testTarget(
            name: "TeleCueTests",
            dependencies: ["TeleCue"],
            path: "Tests/TeleCueTests"
        )
    ],
    swiftLanguageModes: [.v6]
)
