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
        .package(url: "https://github.com/rogerioth/MeshGradient.git", from: "1.0.8"),
        .package(url: "https://github.com/onevcat/RandomColorSwift.git", .branch("master"))
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
            dependencies: ["MeshKit"]),
    ]
)
