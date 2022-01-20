import Foundation
import Nimble
import NQueue
import NSpry
import NSpry_Nimble
import Quick

@testable import NImageDownloader
@testable import NImageDownloaderTestHelpers
@testable import NRequestTestHelpers

final class ImageCacheSpec: QuickSpec {
    override func spec() {
        describe("ImageCache") {
            var subject: ImageCache!
            var fileManager: FakeFileManager!
            var urlCache: URLCache!
            var url: URL!

            beforeEach {
                url = .testMake("file://path/directory")
                let urlUnused: URL = .testMake("file://path/directory")
                let urls: [URL] = [url, urlUnused]

                fileManager = .init()
                fileManager.stub(.urls).andReturn(urls)
                let internalSubject = Impl.ImageCache(fileManager: fileManager)
                subject = internalSubject

                urlCache = internalSubject.urlCache
            }

            if #available(iOS 13, *) {
                it("should create cache with correct path") {
                    let directory: NImageDownloader.FileManager.SearchPathDirectory = .cachesDirectory
                    let domainMask: NImageDownloader.FileManager.SearchPathDomainMask = .userDomainMask
                    expect(fileManager).to(haveReceived(.urls, with: directory, domainMask))
                }
            } else {
                it("should create cache with correct path") {
                    expect(fileManager).toNot(haveReceived(.urls))
                }
            }

            it("should create cache") {
                expect(subject).toNot(beNil())
            }

            it("should create url cache with correct memory usage") {
                expect(urlCache).toNot(beNil())
                expect(urlCache?.diskCapacity) == 400 * 1024 * 1024
                expect(urlCache?.memoryCapacity) == 40 * 1024 * 1024
            }
        }
    }
}

private extension URLRequest {
    static func testMake(name: String) -> Self {
        // cached response needs fulfilled url with all parameters as from real request
        let parts = ["https://www.google.com/image/", name, ".png"].joined()
        return .testMake(url: parts)
    }
}

private extension CachedURLResponse {
    static func testMake(data: Data, urlRequest: URLRequest) -> Self {
        // don't use other type of response, it's may lead to flaky crash
        let response = HTTPURLResponse(url: urlRequest.url.unsafelyUnwrapped,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: nil).unsafelyUnwrapped
        return .init(response: response,
                     data: data,
                     userInfo: [:],
                     storagePolicy: .allowed)
    }
}
