import Foundation

@testable import NImageDownloader

extension Data {
    static func testMake(image: Image.TastableImage = .default) -> Self {
        return PlatformImage(Image.testMake(image)).pngData().unsafelyUnwrapped
    }
}
