// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "CausalLabsSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CausalLabsSDK",
            targets: ["CausalLabsSDK"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CausalLabsSDK",
            path: "Sources"
        ),
        .testTarget(
            name: "CausalLabsSDKTests",
            dependencies: ["CausalLabsSDK"],
            path: "Tests",
            exclude: [
                "UnitTests.xctestplan",
                "Fixtures/TestExample.fdl"
            ]
        )
    ]
)
