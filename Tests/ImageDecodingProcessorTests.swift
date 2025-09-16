#if !supportsVisionOS
import Foundation
import SpryKit
import Threading
import XCTest
@testable import SmartImages

final class ImageDecodingProcessorTests: XCTestCase {
    private let pngData: Data! = PlatformImage(.spry.testImage4).pngData()

    func test_not_nil_png_data() {
        XCTAssertNotNil(pngData)
    }

    func test_empty_decoders_array() throws {
        let subject = ImageDecodingProcessor(decoders: [])
        let actualImage = subject.decode(pngData)
        XCTAssertNotNil(actualImage)
        let unwrapped = try XCTUnwrap(actualImage)
        XCTAssertEqual(PlatformImage(unwrapped).pngData(), PlatformImage(.spry.testImage4).pngData())
    }

    func test_decoders_array() throws {
        let subject = ImageDecodingProcessor(decoders: [ImageDecoders.Default()])
        let actualImage = subject.decode(pngData)
        XCTAssertNotNil(actualImage)
        let unwrapped = try XCTUnwrap(actualImage)
        XCTAssertEqualImage(PlatformImage(unwrapped).pngData(), PlatformImage(.spry.testImage4).pngData())
    }

    func test_broken_data() {
        let subject = ImageDecodingProcessor(decoders: [])
        let actualImage = subject.decode("pngData".data(using: .utf8).unsafelyUnwrapped)
        XCTAssertNil(actualImage)
    }

    func test_when_first_decoder_cant_recognize_data() {
        let decoders: [FakeImageDecoder] = [.init(), .init()]
        let subject = ImageDecodingProcessor(decoders: decoders)

        decoders[0].stub(.decode).andReturn(nil)
        decoders[1].stub(.decode).andReturn(Image.spry.testImage1)

        let actualImage = subject.decode(pngData)

        XCTAssertHaveReceived(decoders[0], .decode, with: pngData)
        XCTAssertHaveReceived(decoders[1], .decode, with: pngData)

        XCTAssertEqual(actualImage, .spry.testImage1)
    }

    func test_when_first_decoder_recognize_data() {
        let decoders: [FakeImageDecoder] = [.init(), .init()]
        let subject = ImageDecodingProcessor(decoders: decoders)

        decoders[0].stub(.decode).andReturn(Image.spry.testImage1)
        decoders[1].stub(.decode).andReturn(nil)

        let actualImage = subject.decode(pngData)

        XCTAssertHaveReceived(decoders[0], .decode, with: pngData)
        XCTAssertHaveNotReceived(decoders[1], .decode, with: pngData)

        XCTAssertEqual(actualImage, .spry.testImage1)
    }
}
#endif
