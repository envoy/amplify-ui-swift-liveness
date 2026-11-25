// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AmplifyUILiveness",
    defaultLocalization: "en",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "FaceLiveness",
            targets: ["FaceLiveness"]),
    ],
    dependencies: [
        .package(url: "https://github.com/aws-amplify/amplify-swift", from: "2.60.2")
    ],
    targets: [
        .target(
            name: "FaceLiveness",
            dependencies: [
                .product(name: "AWSPluginsCore", package: "amplify-swift"),
                .product(name: "AWSCognitoAuthPlugin", package: "amplify-swift"),
                "FaceLivenessStreaming"
            ],
            resources: [
                .process("Resources/Base.lproj"),
                .copy("Resources/face_detection_short_range.mlmodelc")
            ]
        ),
        // Copied from AWSPredictionsPlugin, whose CoreML adapter links Speech and makes App Store Connect demand a purpose string.
        .target(
            name: "FaceLivenessStreaming",
            dependencies: [
                .product(name: "Amplify", package: "amplify-swift"),
                .product(name: "AWSPluginsCore", package: "amplify-swift")
            ]
        ),
        .testTarget(
            name: "FaceLivenessTests",
            dependencies: ["FaceLiveness", "FaceLivenessStreaming"]),
    ]
)
