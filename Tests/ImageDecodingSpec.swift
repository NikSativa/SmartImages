import Foundation
import Nimble
import NSpry
import NSpry_Nimble
import Quick
import UIKit

@testable import NImageDownloader
@testable import NImageDownloaderTestHelpers

final class ImageDecodingSpec: QuickSpec {
    override func spec() {
        describe("ImageDecoding") {
            var subject: ImageDecoding!
            var decoders: [FakeImageDecoder]!
            var pngData: Data!

            beforeEach {
                pngData = UIImage.testMake(.four).pngData()

                decoders = [.init(), .init()]
                subject = Impl.ImageDecoding(decoders: decoders)
            }

            it("should generate expected datas") {
                expect(pngData).toNot(beEmpty())
            }

            context("when first decoder can't recognize data") {
                var actualImage: UIImage?

                beforeEach {
                    decoders[0].stub(.decode).andReturn(nil)
                    decoders[1].stub(.decode).andReturn(UIImage.testMake(.one))

                    subject.decode(pngData)
                        .onComplete {
                            actualImage = $0
                        }
                }

                it("should decoded via the second decoder") {
                    expect(decoders[0]).to(haveReceived(.decode, with: pngData))
                    expect(decoders[1]).to(haveReceived(.decode, with: pngData))
                }

                it("should generate corresponding image") {
                    expect(actualImage) == UIImage.testMake(.one)
                }
            }

            context("when first decoder recognize data") {
                var actualImage: UIImage?

                beforeEach {
                    decoders[0].stub(.decode).andReturn(UIImage.testMake(.one))
                    decoders[1].stub(.decode).andReturn(nil)

                    subject.decode(pngData)
                        .onComplete {
                            actualImage = $0
                        }
                }

                it("should decoded via the first decoder and ignore the second one") {
                    expect(decoders[0]).to(haveReceived(.decode, with: pngData))
                    expect(decoders[1]).toNot(haveReceived(.decode))
                }

                it("should generate corresponding image") {
                    expect(actualImage) == UIImage.testMake(.one)
                }
            }
        }
    }
}
