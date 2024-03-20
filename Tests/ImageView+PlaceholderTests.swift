#if !os(watchOS)
import Foundation
import NSpry
import XCTest

@testable import NImageDownloader
@testable import NImageDownloaderTestHelpers

final class ImageView_PlaceholderTests: XCTestCase {
    func test_placeholder() {
        let subject = ImageView()
        XCTAssertNil(subject.image)

        subject.setPlaceholder(.spry.testImage1)
        XCTAssertEqual(subject.image, .spry.testImage1)

        subject.setPlaceholder()
        XCTAssertNil(subject.image)

        subject.setPlaceholder(.spry.testImage2)
        XCTAssertEqual(subject.image, .spry.testImage2)
    }
}
#endif
