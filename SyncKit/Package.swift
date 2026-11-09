// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SyncKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "SyncKit",
            targets: ["SyncKit"]
        ),
    ],
    dependencies: [
        .package(path: "../CRDTKit"),
    ],
    targets: [
        .target(
            name: "SyncKit",
            dependencies: [
                .product(name: "CRDTKit", package: "CRDTKit"),
            ]
        ),
        .testTarget(
            name: "SyncKitTests",
            dependencies: ["SyncKit"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

