// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Domicile",
    defaultLocalization: "en",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.0"),
    ],
    targets: [
        .target(
            name: "DomicileCore",
            resources: [.process("Resources")],
            linkerSettings: [
                .linkedFramework("CoreWLAN"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("Security"),
            ]
        ),
        .executableTarget(
            name: "domicile",
            dependencies: [
                "DomicileCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "DomicileCoreTests",
            dependencies: ["DomicileCore"]
        ),
    ]
)
