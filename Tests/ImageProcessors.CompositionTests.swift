import Foundation
import SpryKit
import XCTest

@testable import FastImages
@testable import FastImagesTestHelpers

final class ImageProcessors_CompositionTests: XCTestCase {
    func test_2_processors() {
        let processors: [FakeImageProcessor] = [.init(), .init()]
        let subject: ImageProcessor = ImageProcessors.Composition(processors: processors)

        processors[0].stub(.process).andReturn(Image.spry.testImage1)
        processors[1].stub(.process).andReturn(Image.spry.testImage2)

        let actualImage = subject.process(Image.spry.testImage)
        XCTAssertEqual(actualImage, Image.spry.testImage2)

        XCTAssertHaveReceived(processors[0], .process, with: Image.spry.testImage)
        XCTAssertHaveReceived(processors[1], .process, with: Image.spry.testImage1)
    }

    func test_empty() {
        let subject: ImageProcessor = ImageProcessors.Composition(processors: [])
        let actualImage = subject.process(Image.spry.testImage1)
        XCTAssertEqual(actualImage, Image.spry.testImage1)
    }
}
