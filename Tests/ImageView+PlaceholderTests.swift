import Foundation
import SmartImages
import SpryKit
import XCTest

final class ImageView_PlaceholderTests: XCTestCase {
    #if swift(>=6.0)
    @MainActor
    #endif
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
private final class ImageView: SmartImages.ImageView {
    var image: Image?
}
#endif
