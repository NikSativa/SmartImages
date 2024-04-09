import Foundation
import SpryKit
import XCTest

@testable import FastImages
@testable import FastImagesTestHelpers

final class ImagePriorityTests: XCTestCase {
    func test_priority() {
        XCTAssertEqual(ImagePriority.default, .normal)
        XCTAssertEqual(ImagePriority.prefetch, .veryLow)
    }
}
