// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IncentivlyIOSSDK",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "IncentivlyIOSSDK",
            targets: ["IncentivlyIOSSDK"]),
    ],
    dependencies: [
        // No external dependencies needed as StoreKit 2 is part of the system
    ],
    targets: [
        .target(
            name: "IncentivlyIOSSDK",
            dependencies: []),
        .testTarget(
            name: "IncentivlyIOSSDKTests",
            dependencies: ["IncentivlyIOSSDK"]),
    ]
)