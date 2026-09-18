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
    targets: [
        .executableTarget(
            name: "TeleCue",
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

