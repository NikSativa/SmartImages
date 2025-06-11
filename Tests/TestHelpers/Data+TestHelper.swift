import Foundation
import SpryKit
@testable import SmartImages

extension Data {
    static func testMake(image: Image = .spry.testImage) -> Self {
        return PlatformImage(image).pngData().unsafelyUnwrapped
    }
}
