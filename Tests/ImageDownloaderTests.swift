import Combine
import Foundation
import SpryKit
import Threading
import XCTest

@testable import SmartImages

final class ImageDownloaderTests: XCTestCase, @unchecked Sendable {
    private lazy var task: FakeImageDownloaderTask = {
        let task = FakeImageDownloaderTask()
        task.stub(.start).andReturn()
        return task
    }()

    private lazy var network: FakeImageDownloaderNetwork = {
        let network = FakeImageDownloaderNetwork()
        network.stub(.request).andReturn(task)
        return network
    }()

    private lazy var imageCache: FakeImageCaching = {
        let imageCache = FakeImageCaching()
        imageCache.stub(.cached).andReturn(nil)
        imageCache.stub(.store).andReturn()
        return imageCache
    }()

    private lazy var imageDecoding: ImageDecodingProcessor = .init(decoders: [])

    private lazy var downloadQueue: FakeImageDownloadQueueing = {
        let downloadQueue = FakeImageDownloadQueueing()
        downloadQueue.stub(.add).andReturn()
        return downloadQueue
    }()

    private lazy var subject = ImageDownloader(network: network,
                                               decodingQueue: .async(Queue.background),
                                               imageCache: imageCache,
                                               imageDecoding: imageDecoding,
                                               downloadQueue: downloadQueue)
    private var token: AnyCancellable?

    func test_download_url_success() {
        let expImage = expectation(description: "wait image")
        token = subject.download(url: .testMake("google.com/\(1)")) { img in
            XCTAssertEqualImage(img, .spry.testImage4)
            expImage.fulfill()
        }

        let expLoading = expectation(description: "wait loading")
        downloadQueue.starter? {
            expLoading.fulfill()
        }

        XCTAssertHaveNotReceived(imageCache, .store)

        let image: Image = .spry.testImage4
        let imageData: Data = PlatformImage(image).pngData()!
        Queue.utility.asyncAfter(deadline: .now() + 0.1) { [network] in
            network.completion?(.success(imageData))
        }
        XCTAssertHaveNotReceived(imageCache, .store)

        wait(for: [expLoading, expImage], timeout: 10)

        XCTAssertHaveReceived(imageCache, .store)

        // should not call cancel
        token = nil
    }

    func test_cancel() {
        task.stub(.cancel).andReturn()

        let expImage = expectation(description: "wait image")
        expImage.isInverted = true
        token = subject.download(url: .testMake("google.com/\(1)")) { _ in
            expImage.fulfill()
        }

        let expLoading = expectation(description: "wait loading")
        expLoading.isInverted = true
        downloadQueue.starter? {
            expLoading.fulfill()
        }

        XCTAssertHaveNotReceived(imageCache, .store)

        let expToken = expectation(description: "wait token")
        Queue.utility.asyncAfter(deadline: .now() + 0.1) { [unowned self] in
            token = nil
            expToken.fulfill()
        }
        XCTAssertHaveNotReceived(imageCache, .store)

        wait(for: [expLoading, expImage, expToken], timeout: 10)

        XCTAssertHaveReceived(task, .cancel)
    }

    func test_create() {
        let network = FakeImageDownloaderNetwork()
        let cache = ImageCacheInfo(folderName: "ImageDownloaderTests.ImageCacheInfo.folderName")
        let subject: ImageDownloading? = ImageDownloader.create(network: network,
                                                                cache: cache)
        XCTAssertNotNil(subject)
    }

    func test_download_url_multy() {
        let rands: () -> TimeInterval = {
            return TimeInterval((0...1000).randomElement()!) / 10000
        }

        let network = FakeImageDownloaderNetwork()
        let subject: ImageDownloading = ImageDownloader.create(network: network,
                                                               cache: nil,
                                                               concurrentImagesLimit: 10)

        let limit = 100
        var tokens: Set<AnyCancellable> = []
        var expsResult: [XCTestExpectation] = []
        let expsLoading: SendableResult<[XCTestExpectation]> = .init(value: [])

        downloadQueue.resetStubs()
        downloadQueue.stub(.add).andDo { args in
            let sendableArgs = SendableResult(value: args)
            Queue.main.asyncAfter(deadline: .now() + rands()) {
                let url = (sendableArgs.value[0] as? URL)!
                let ind: Int = .init(url.absoluteString.components(separatedBy: "/").last!)!

                (sendableArgs.value[2] as? FakeImageDownloadQueueing.StarterClosure)! {
                    expsLoading.value[ind].fulfill()
                }
            }
            return ()
        }

        for i in 0..<limit {
            let url: URL = .testMake("google.com/\(i)")
            let expLoading = expectation(description: "wait \(i) loading")
            expsLoading.value.append(expLoading)

            network.stub(.request).with(url, Argument.anything, Argument.anything, Argument.anything).andDo { args in
                // swiftformat:disable:next all
                let completion = SendableResult(value: args[3] as? (Result<Data, Error>) -> Void)
                if i < limit / 2 {
                    let image: Image = .spry.testImage4
                    let imageData: Data = PlatformImage(image).pngData()!
                    Queue.main.asyncAfter(deadline: .now() + rands()) {
                        completion.value(.success(imageData))
                        expLoading.fulfill()
                    }
                } else {
                    Queue.main.asyncAfter(deadline: .now() + rands()) {
                        completion.value(.failure(URLError(URLError.Code.badServerResponse)))
                        expLoading.fulfill()
                    }
                }

                let task = FakeImageDownloaderTask()
                task.stub(.start).andReturn()
                task.stub(.cancel).andReturn()

                return task
            }

            let expResult = expectation(description: "wait \(i) image")
            expsResult.append(expResult)

            subject.download(url: url) { img in
                if i < limit / 2 {
                    XCTAssertEqualImage(img, .spry.testImage4)
                } else {
                    XCTAssertNil(img)
                }
                expResult.fulfill()
            }.store(in: &tokens)
        }

        wait(for: expsResult + expsLoading.value, timeout: 10)

        // should not call cancel
        // try to make 'timeout: 10' to by sure that every task was finished correctly
        tokens = []
    }
}
