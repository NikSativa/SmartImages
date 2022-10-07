import Foundation
import Nimble
import NSpry
import NSpry_Nimble
import Quick

@testable import NImageDownloader
@testable import NImageDownloaderTestHelpers

final class ImageProcessingSpec: QuickSpec {
    override func spec() {
        describe("ImageProcessing") {
            var subject: ImageProcessing!
            var processors: [FakeImageProcessor]!

            beforeEach {
                processors = [
                    .init(),
                    .init()
                ]
                subject = Impl.ImageProcessing()
            }

            describe("processing image") {
                var actualImage: Image?

                beforeEach {
                    processors[0].stub(.process).andReturn(Image.testMake(.two))
                    processors[1].stub(.process).andReturn(Image.testMake(.three))

                    subject.process(Image.testMake(.one),
                                    processors: processors)
                        .onComplete {
                            actualImage = $0
                        }
                }

                it("should proccess image") {
                    expect(processors[0]).to(haveReceived(.process, with: Image.testMake(.one)))
                    expect(processors[1]).to(haveReceived(.process, with: Image.testMake(.two)))
                }

                it("should generate corresponding image") {
                    expect(actualImage) == Image.testMake(.three)
                }
            }
        }
    }
}
