// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MeshKit",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
        .macCatalyst(.v14),
        .tvOS(.v14),
    ],
    products: [
        .library(
            name: "MeshKit",
            targets: ["MeshKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/rogerioth/MeshGradient.git", from: "1.1.2"),
        .package(url: "https://github.com/rogerioth/RandomColorSwift.git", from: "2.0.1"),
        .package(url: "https://github.com/Quick/Quick.git", from: "4.0.0"), // Quick
        .package(url: "https://github.com/Quick/Nimble.git", from: "9.0.0"), // Nimble
    ],
    targets: [
        .target(
            name: "MeshKit",
            dependencies: [
                .product(name: "MeshGradient", package: "meshgradient"),
                .product(name: "RandomColor", package: "randomcolorswift")
            ]),
        .testTarget(
            name: "MeshKitTests",
            dependencies: ["MeshKit", "Quick", "Nimble"]), // Add Quick and Nimble here
    ]
)
