// swift-tools-version:5.5
// swiftformat:disable all
import PackageDescription

let package = Package(
    name: "FastImages",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "FastImages", targets: ["FastImages"]),
        .library(name: "FastImagesTestHelpers", targets: ["FastImagesTestHelpers"])
    ],
    dependencies: [
        .package(url: "https://github.com/NikSativa/Threading.git", .upToNextMajor(from: "1.2.4")),
        .package(url: "https://github.com/NikSativa/SpryKit.git", .upToNextMajor(from: "2.1.4"))
    ],
    targets: [
        .target(name: "FastImages",
                dependencies: [
                    "Threading"
                ],
                path: "Source",
                resources: [
                    .copy("../PrivacyInfo.xcprivacy")
                ]),
        .target(name: "FastImagesTestHelpers",
                dependencies: [
                    "SpryKit",
                    "FastImages"
                ],
                path: "TestHelpers",
                resources: [
                    .copy("../PrivacyInfo.xcprivacy")
                ]),
        .testTarget(name: "FastImagesTests",
                    dependencies: [
                        "FastImages",
                        "FastImagesTestHelpers",
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
