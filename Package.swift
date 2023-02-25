// swift-tools-version:5.6
// swiftformat:disable all
import PackageDescription

let package = Package(
    name: "NImageDownloader",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(name: "NImageDownloader", targets: ["NImageDownloader"]),
        .library(name: "NImageDownloaderTestHelpers", targets: ["NImageDownloaderTestHelpers"])
    ],
    dependencies: [
        .package(url: "https://github.com/NikSativa/NRequest.git", .upToNextMajor(from: "3.4.1")),
        .package(url: "https://github.com/NikSativa/NCallback.git", .upToNextMajor(from: "2.10.12")),
        .package(url: "https://github.com/NikSativa/NQueue.git", .upToNextMajor(from: "1.1.14")),
        .package(url: "https://github.com/NikSativa/NSpry.git", .upToNextMajor(from: "1.2.9")),
        .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "6.1.0")),
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "11.2.1"))
    ],
    targets: [
        .target(name: "NImageDownloader",
                dependencies: [
                    "NRequest",
                    "NCallback",
                    "NQueue"
                ],
                path: "Source"),
        .target(name: "NImageDownloaderTestHelpers",
                dependencies: [
                    "NSpry",
                    "NRequest",
                    "NImageDownloader",
                    .product(name: "NRequestTestHelpers", package: "NRequest")
                ],
                path: "TestHelpers"),
        .testTarget(name: "NImageDownloaderTests",
                    dependencies: [
                        "NImageDownloader",
                        "NImageDownloaderTestHelpers",
                        "NRequest",
                        .product(name: "NRequestTestHelpers", package: "NRequest"),
                        "NCallback",
                        .product(name: "NCallbackTestHelpers", package: "NCallback"),
                        "NSpry",
                        .product(name: "NSpry_Nimble", package: "NSpry"),
                        "Nimble",
                        "Quick"
                    ],
                    path: "Tests",
                    resources: [
                        .process("TestImages")
                    ])
    ]
)
