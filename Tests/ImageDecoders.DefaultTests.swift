import Foundation
import SpryKit
import XCTest
@testable import SmartImages

final class ImageDecoders_DefaultTests: XCTestCase {
    func test_should_not_create_image_from_empty_Data() {
        let subject = ImageDecoders.Default()
        XCTAssertNil(subject.decode(Data()))
    }

    func test_should_not_create_image_from_unsupported_or_broken_file() {
        let url = Bundle.module.url(forResource: "unsupported", withExtension: "txt").unsafelyUnwrapped
        let data = (try? Data(contentsOf: url)).unsafelyUnwrapped
        let subject = ImageDecoders.Default()
        XCTAssertNil(subject.decode(data))
    }

    func test_should_not_create_image_from_unsupported_or_broken_format() {
        let data = "(try? Data(contentsOf: url)).unsafelyUnwrapped".data(using: .utf8).unsafelyUnwrapped
        let subject = ImageDecoders.Default()
        XCTAssertNil(subject.decode(data))
    }

    func test_should_create_image_from_png_file() {
        let url = Bundle.module.url(forResource: "rgb_1", withExtension: "png").unsafelyUnwrapped
        let data = (try? Data(contentsOf: url)).unsafelyUnwrapped
        let expectedImage = PlatformImage(data: data)
        XCTAssertNotNil(expectedImage)

        let subject = ImageDecoders.Default()
        XCTAssertEqual(subject.decode(data).map(PlatformImage.init)?.pngData(), expectedImage?.pngData())
    }
}
