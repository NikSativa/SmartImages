import Foundation
import SmartImages
import SpryKit
import XCTest

final class ImageProcessors_CompositionTests: XCTestCase {
    func test_2_processors() {
        let processors: [FakeImageProcessor] = [.init(), .init()]
        let subject: ImageProcessor = ImageProcessors.Composition(processors: processors)

        processors[0].stub(.process).andReturn(SmartImage.spry.testImage1)
        processors[1].stub(.process).andReturn(SmartImage.spry.testImage2)

        let actualImage = subject.process(SmartImage.spry.testImage)
        XCTAssertEqual(actualImage, SmartImage.spry.testImage2)

        XCTAssertHaveReceived(processors[0], .process, with: SmartImage.spry.testImage)
        XCTAssertHaveReceived(processors[1], .process, with: SmartImage.spry.testImage1)
    }

    func test_empty() {
        let subject: ImageProcessor = ImageProcessors.Composition(processors: [])
        let actualImage = subject.process(SmartImage.spry.testImage1)
        XCTAssertEqual(actualImage, SmartImage.spry.testImage1)
    }
}
