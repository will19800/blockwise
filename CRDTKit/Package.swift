// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CRDTKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "CRDTKit",
            targets: ["CRDTKit"]
        ),
        .executable(
            name: "crdt-fuzz",
            targets: ["CRDTFuzz"]
        ),
    ],
    targets: [
        .target(
            name: "CRDTKit"
        ),
        .executableTarget(
            name: "CRDTFuzz",
            dependencies: ["CRDTFuzzSupport"]
        ),
        .target(
            name: "CRDTFuzzSupport",
            dependencies: ["CRDTKit"]
        ),
        .testTarget(
            name: "CRDTKitTests",
            dependencies: ["CRDTKit", "CRDTFuzzSupport"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

