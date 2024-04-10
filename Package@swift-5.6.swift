// swift-tools-version:5.6
// swiftformat:disable all
import PackageDescription

let package = Package(
    name: "SmartImages",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "SmartImages", targets: ["SmartImages"]),
        .library(name: "SmartImagesTestHelpers", targets: ["SmartImagesTestHelpers"])
    ],
    dependencies: [
        .package(url: "https://github.com/NikSativa/Threading.git", .upToNextMajor(from: "1.2.4")),
        .package(url: "https://github.com/NikSativa/SpryKit.git", .upToNextMajor(from: "2.1.4"))
    ],
    targets: [
        .target(name: "SmartImages",
                dependencies: [
                    "Threading"
                ],
                path: "Source",
                resources: [
                    .copy("../PrivacyInfo.xcprivacy")
                ]),
        .target(name: "SmartImagesTestHelpers",
                dependencies: [
                    "SpryKit",
                    "SmartImages"
                ],
                path: "TestHelpers",
                resources: [
                    .copy("../PrivacyInfo.xcprivacy")
                ]),
        .testTarget(name: "SmartImagesTests",
                    dependencies: [
                        "SmartImages",
                        "SmartImagesTestHelpers",
                        "SpryKit",
                        "Threading",
                        .product(name: "ThreadingTestHelpers", package: "Threading")
                    ],
                    path: "Tests",
                    resources: [
                        .process("TestImages")
                    ])
    ]
)
