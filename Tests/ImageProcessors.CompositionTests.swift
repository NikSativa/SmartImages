import Foundation
import NSpry
import XCTest

@testable import NImageDownloader
@testable import NImageDownloaderTestHelpers

final class ImageProcessors_CompositionTests: XCTestCase {
    func test_2_processors() {
        let processors: [FakeImageProcessor] = [.init(), .init()]
        let subject: ImageProcessor = ImageProcessors.Composition(processors: processors)

        processors[0].stub(.process).andReturn(Image.testMake(.two))
        processors[1].stub(.process).andReturn(Image.testMake(.three))

        let actualImage = subject.process(Image.testMake(.one))
        XCTAssertEqual(actualImage, Image.testMake(.three))

        XCTAssertHaveReceived(processors[0], .process, with: Image.testMake(.one))
        XCTAssertHaveReceived(processors[1], .process, with: Image.testMake(.two))
    }

    func test_empty() {
        let subject: ImageProcessor = ImageProcessors.Composition(processors: [])
        let actualImage = subject.process(Image.testMake(.one))
        XCTAssertEqual(actualImage, Image.testMake(.one))
    }
}
