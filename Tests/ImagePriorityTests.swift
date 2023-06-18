import Foundation
import NSpry
import XCTest

@testable import NImageDownloader
@testable import NImageDownloaderTestHelpers

final class ImagePriorityTests: XCTestCase {
    func test_priority() {
        XCTAssertEqual(ImagePriority.default, .normal)
        XCTAssertEqual(ImagePriority.prefetch, .veryLow)
    }
}
