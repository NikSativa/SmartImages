import Foundation
import NImageDownloader
import NImageDownloaderTestHelpers
import NSpry
import XCTest

final class ImageView_PlaceholderTests: XCTestCase {
    func test_placeholder() {
        let subject = ImageView()
        XCTAssertNil(subject.image)

        subject.setPlaceholder(.image(.spry.testImage1))
        XCTAssertEqual(subject.image, .spry.testImage1)

        subject.setPlaceholder(.clear)
        XCTAssertNil(subject.image)

        subject.setPlaceholder(.none)
        XCTAssertNil(subject.image)

        subject.setPlaceholder(.init(.spry.testImage2))
        XCTAssertEqual(subject.image, .spry.testImage2)

        subject.setPlaceholder(.none)
        XCTAssertEqual(subject.image, .spry.testImage2)

        subject.setPlaceholder(.init(nil))
        XCTAssertNil(subject.image)

        subject.setPlaceholder(.init(.spry.testImage2))
        subject.setPlaceholder(.none)
        XCTAssertEqual(subject.image, .spry.testImage2)
    }
}

#if os(watchOS)
private final class ImageView: NImageDownloader.ImageView {
    var image: Image?
}
#endif
