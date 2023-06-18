// swift-tools-version:5.8
// swiftformat:disable all
import PackageDescription

let package = Package(
    name: "NImageDownloader",
    platforms: [
        .iOS(.v13),
        .macOS(.v11)
    ],
    products: [
        .library(name: "NImageDownloader", targets: ["NImageDownloader"]),
        .library(name: "NImageDownloaderTestHelpers", targets: ["NImageDownloaderTestHelpers"])
    ],
    dependencies: [
        .package(url: "https://github.com/NikSativa/NQueue.git", .upToNextMajor(from: "1.2.2")),
        .package(url: "https://github.com/NikSativa/NSpry.git", .upToNextMajor(from: "2.1.2"))
    ],
    targets: [
        .target(name: "NImageDownloader",
                dependencies: [
                    "NQueue"
                ],
                path: "Source"),
        .target(name: "NImageDownloaderTestHelpers",
                dependencies: [
                    "NSpry",
                    "NImageDownloader"
                ],
                path: "TestHelpers"),
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
