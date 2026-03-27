// swift-tools-version:5.10
// swiftformat:disable all
import PackageDescription

let package = Package(
    name: "SmartImages",
    platforms: [
        .iOS(.v16),
        .macOS(.v14),
        .macCatalyst(.v16),
        .visionOS(.v1),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(name: "SmartImages", targets: ["SmartImages"]),
        .library(name: "SmartImagesUIKit", targets: ["SmartImages", "SmartImagesUIKit"]),
        .library(name: "SmartImagesSwiftUI", targets: ["SmartImages", "SmartImagesSwiftUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/NikSativa/Threading.git", from: "2.3.0"),
        .package(url: "https://github.com/NikSativa/SpryKit.git", from: "3.2.0")
    ],
    targets: [
        .target(name: "SmartImages",
                dependencies: [
                    "Threading",
                ],
                path: "Source",
                exclude: [
                    "UIKit",
                    "SwiftUI",
                ],
                resources: [
                    .process("PrivacyInfo.xcprivacy"),
                ],
                swiftSettings: [
                    .define("supportsVisionOS", .when(platforms: [.visionOS])),
                ]),
        .target(name: "SmartImagesUIKit",
                dependencies: [
                    "SmartImages",
                    "Threading",
                ],
                path: "Source/UIKit",
                swiftSettings: [
                    .define("supportsVisionOS", .when(platforms: [.visionOS])),
                ]),
        .target(name: "SmartImagesSwiftUI",
                dependencies: [
                    "SmartImages",
                    "Threading",
                ],
                path: "Source/SwiftUI",
                swiftSettings: [
                    .define("supportsVisionOS", .when(platforms: [.visionOS])),
                ]),
        .testTarget(name: "SmartImagesTests",
                    dependencies: [
                        "SmartImages",
                        "SmartImagesUIKit",
                        "SmartImagesSwiftUI",
                        "SpryKit",
                        "Threading",
                    ],
                    path: "Tests",
                    resources: [
                        .process("TestImages"),
                    ],
                    swiftSettings: [
                        .define("supportsVisionOS", .when(platforms: [.visionOS])),
                    ]),
    ]
)
