import Foundation
import Nimble
import NSpry
import NSpry_Nimble
import Quick

@testable import NImageDownloader
@testable import NImageDownloaderTestHelpers

final class ImageDecoders_DefaultSpec: QuickSpec {
    override func spec() {
        describe("ImageDecoders.Default") {
            var subject: ImageDecoder!
            var bundle: Bundle!

            beforeEach {
                #if SWIFT_PACKAGE
                bundle = Bundle.module
                #else
                bundle = Bundle(for: ImageDecoders_DefaultSpec.self)
                #endif

                subject = ImageDecoders.Default()
            }

            it("should create subject") {
                expect(subject).toNot(beNil())
            }

            it("should not create image from empty Data") {
                expect(subject.decode(Data())).to(beNil())
            }

            it("should not create image from unsupported/broken file") {
                let url = bundle.url(forResource: "unsupported", withExtension: "txt").unsafelyUnwrapped
                let data = (try? Data(contentsOf: url)).unsafelyUnwrapped
                expect(subject.decode(data)).to(beNil())
            }

            it("should not create image from unsupported/broken format") {
                let data = "(try? Data(contentsOf: url)).unsafelyUnwrapped".data(using: .utf8).unsafelyUnwrapped
                expect(subject.decode(data)).to(beNil())
            }

            it("should create image from png file") {
                let url = bundle.url(forResource: "rgb_1", withExtension: "png").unsafelyUnwrapped
                let data = (try? Data(contentsOf: url)).unsafelyUnwrapped
                let expectedImage = PlatformImage(data: data)
                expect(expectedImage).toNot(beNil())
                expect(subject.decode(data).map(PlatformImage.init)?.pngData()) == expectedImage?.pngData()
            }
        }
    }
}
