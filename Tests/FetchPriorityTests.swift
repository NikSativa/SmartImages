import Foundation
import SmartImages
import SpryKit
import XCTest

final class ImagePriorityTests: XCTestCase {
    func test_priority() {
        XCTAssertEqual(FetchPriority.default, .normal)
        XCTAssertEqual(FetchPriority.prefetch, .veryLow)
    }
}
