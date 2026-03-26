import Foundation
import SpryKit
@testable import SmartImages

extension Data {
    static func testMake(image: SmartImage = .spry.testImage) -> Self {
        return PlatformImage(image).pngData().unsafelyUnwrapped
    }
}
