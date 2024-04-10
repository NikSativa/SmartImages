import Foundation
import SmartImages
import SpryKit
import XCTest

final class ImagePriorityTests: XCTestCase {
    func test_priority() {
        XCTAssertEqual(ImagePriority.default, .normal)
        XCTAssertEqual(ImagePriority.prefetch, .veryLow)
    }
}
