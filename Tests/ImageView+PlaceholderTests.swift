import Foundation
import NSpry
import XCTest

@testable import NImageDownloader
@testable import NImageDownloaderTestHelpers

final class ImageView_PlaceholderTests: XCTestCase {
    func test_placeholder() {
        let subject = ImageView()
        XCTAssertNil(subject.image)

        subject.setPlaceholder(.testMake(.five))
        XCTAssertEqual(subject.image, .testMake(.five))

        subject.setPlaceholder()
        XCTAssertNil(subject.image)

        subject.setPlaceholder(.testMake(.three))
        XCTAssertEqual(subject.image, .testMake(.three))
    }
}
