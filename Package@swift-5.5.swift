// swift-tools-version:5.5
// swiftformat:disable all
import PackageDescription

let package = Package(
    name: "NImageDownloader",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "NImageDownloader", targets: ["NImageDownloader"]),
        .library(name: "NImageDownloaderTestHelpers", targets: ["NImageDownloaderTestHelpers"])
    ],
    dependencies: [
        .package(url: "https://github.com/NikSativa/NQueue.git", .upToNextMajor(from: "1.2.4")),
        .package(url: "https://github.com/NikSativa/NSpry.git", .upToNextMajor(from: "2.1.4"))
    ],
    targets: [
        .target(name: "NImageDownloader",
                dependencies: [
                    "NQueue"
                ],
                path: "Source",
                resources: [
                    .copy("../PrivacyInfo.xcprivacy")
                ]),
        .target(name: "NImageDownloaderTestHelpers",
                dependencies: [
                    "NSpry",
                    "NImageDownloader"
                ],
                path: "TestHelpers",
                resources: [
                    .copy("../PrivacyInfo.xcprivacy")
                ]),
        .testTarget(name: "NImageDownloaderTests",
                    dependencies: [
                        "NImageDownloader",
                        "NImageDownloaderTestHelpers",
                        "NSpry",
                        "NQueue",
                        .product(name: "NQueueTestHelpers", package: "NQueue")
                    ],
                    path: "Tests",
                    resources: [
                        .process("TestImages")
                    ])
    ]
)
