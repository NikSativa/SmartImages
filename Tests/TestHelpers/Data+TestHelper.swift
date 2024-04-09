import Foundation
import SpryKit

@testable import FastImages

extension Data {
    static func testMake(image: Image = .spry.testImage) -> Self {
        return PlatformImage(image).pngData().unsafelyUnwrapped
    }
}
