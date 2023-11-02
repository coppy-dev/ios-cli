// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "coppy-generator",
    platforms: [.macOS(.v12)],
    products: [
        .executable(
            name: "coppy",
            targets: ["coppyCli"]),
    ],
    targets: [
        .executableTarget(
            name: "coppyCli",
            dependencies: []),
        .testTarget(
            name: "coppyCliTests",
            dependencies: ["coppyCli"]),
    ]
)
