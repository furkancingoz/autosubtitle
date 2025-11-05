// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AutoSubtitle",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "AutoSubtitle",
            targets: ["AutoSubtitle"]),
    ],
    dependencies: [
        // Firebase SDK
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            from: "10.20.0"
        ),
        // RevenueCat SDK
        .package(
            url: "https://github.com/RevenueCat/purchases-ios.git",
            from: "4.37.0"
        ),
    ],
    targets: [
        .target(
            name: "AutoSubtitle",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "RevenueCat", package: "purchases-ios"),
            ]
        ),
        .testTarget(
            name: "AutoSubtitleTests",
            dependencies: ["AutoSubtitle"]
        ),
    ]
)
