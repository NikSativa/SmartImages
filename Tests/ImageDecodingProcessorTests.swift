import Foundation
import NSpry
import XCTest

@testable import NImageDownloader
@testable import NImageDownloaderTestHelpers

final class ImageDecodingProcessorTests: XCTestCase {
    private let pngData: Data! = PlatformImage(Image.testMake(.four)).pngData()

    func test_not_nil_png_data() {
        XCTAssertNotNil(pngData)
    }

    func test_empty_decoders_array() {
        let subject = ImageDecodingProcessor(decoders: [])
        let actualImage = subject.decode(pngData)
        XCTAssertNotNil(actualImage)
        if let actualImage {
            XCTAssertEqual(PlatformImage(actualImage).pngData(), PlatformImage(Image.testMake(.four)).pngData())
        }
    }

    func test_decoders_array() {
        let subject = ImageDecodingProcessor(decoders: [ImageDecoders.Default()])
        let actualImage = subject.decode(pngData)
        XCTAssertNotNil(actualImage)
        if let actualImage {
            XCTAssertEqual(PlatformImage(actualImage).pngData(), PlatformImage(Image.testMake(.four)).pngData())
        }
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
        decoders[1].stub(.decode).andReturn(Image.testMake(.one))

        let actualImage = subject.decode(pngData)

        XCTAssertHaveReceived(decoders[0], .decode, with: pngData)
        XCTAssertHaveReceived(decoders[1], .decode, with: pngData)

        XCTAssertEqual(actualImage, Image.testMake(.one))
    }

    func test_when_first_decoder_recognize_data() {
        let decoders: [FakeImageDecoder] = [.init(), .init()]
        let subject = ImageDecodingProcessor(decoders: decoders)

        decoders[0].stub(.decode).andReturn(Image.testMake(.one))
        decoders[1].stub(.decode).andReturn(nil)

        let actualImage = subject.decode(pngData)

        XCTAssertHaveReceived(decoders[0], .decode, with: pngData)
        XCTAssertHaveNotReceived(decoders[1], .decode, with: pngData)

        XCTAssertEqual(actualImage, Image.testMake(.one))
    }
}
