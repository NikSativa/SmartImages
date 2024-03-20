import Foundation
import NSpry

@testable import NImageDownloader

extension Data {
    static func testMake(image: Image = .spry.testImage) -> Self {
        return PlatformImage(image).pngData().unsafelyUnwrapped
    }
}
