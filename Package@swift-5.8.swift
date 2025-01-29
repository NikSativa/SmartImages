// swift-tools-version:5.8
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
        .library(name: "SmartImages", targets: ["SmartImages"])
    ],
    dependencies: [
        .package(url: "https://github.com/NikSativa/Threading.git", .upToNextMajor(from: "2.1.0")),
        .package(url: "https://github.com/NikSativa/SpryKit.git", .upToNextMajor(from: "3.0.1"))
    ],
    targets: [
        .target(name: "SmartImages",
                dependencies: [
                    "Threading"
                ],
                path: "Source",
                resources: [
                    .process("PrivacyInfo.xcprivacy")
                ]),
        .testTarget(name: "SmartImagesTests",
                    dependencies: [
                        "SmartImages",
                        "SpryKit",
                        "Threading",
                    ],
                    path: "Tests",
                    resources: [
                        .process("TestImages")
                    ])
    ]
)
