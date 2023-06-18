import Foundation
import NQueue
import NSpry
import XCTest

@testable import NImageDownloader
@testable import NImageDownloaderTestHelpers
@testable import NQueueTestHelpers

final class ImageDownloadQueueTests: XCTestCase {
    func test_unlimited() {
        let queue = FakeQueueable()
        queue.stub(.async).andDo { args in
            if let task = args[0] as? VoidClosure {
                task()
            }
            return ()
        }

        let subject = ImageDownloadQueue(concurrentImagesLimit: nil,
                                         operationQueue: queue)
        var started: [Int] = []

        for i in 0..<100 {
            subject.add(hash: i) {
                return .preset(.normal)
            } starter: { _ in
                started.append(i)
            }
            queue.asyncWorkItem?()
        }

        XCTAssertEqual(started.count, 100)
    }

    func test_limited() {
        let limit = 5
        let queue = FakeQueueable()
        queue.stub(.async).andDo { args in
            if let task = args[0] as? VoidClosure {
                task()
            }
            return ()
        }

        let subject = ImageDownloadQueue(concurrentImagesLimit: limit,
                                         operationQueue: queue)
        var started: [Int: VoidClosure] = [:]

        for i in 0..<100 {
            subject.add(hash: i) {
                return .preset(.normal)
            } starter: { completion in
                started[i] = {
                    started[i] = nil
                    completion()
                }
            }
        }

        subject.add(hash: "google.com/hasImageView") {
            return .hasImageView
        } starter: { completion in
            started[111] = {
                started[111] = nil
                completion()
            }
        }

        XCTAssertEqual(started.count, limit)
        XCTAssertEqual(started.keys.sorted(), [0, 1, 2, 3, 4])

        started[0]!()
        XCTAssertEqual(started.count, limit)
        XCTAssertEqual(started.keys.sorted(), [1, 2, 3, 4, 111]) // added by priority 'hasImageView'

        started[1]!()
        XCTAssertEqual(started.count, limit)
        XCTAssertEqual(started.keys.sorted(), [2, 3, 4, 99, 111]) // added from the end by timestamp

        started[111]!()
        XCTAssertEqual(started.count, limit)
        XCTAssertEqual(started.keys.sorted(), [2, 3, 4, 98, 99]) // added from the end by timestamp

        started[3]!()
        XCTAssertEqual(started.count, limit)
        XCTAssertEqual(started.keys.sorted(), [2, 4, 97, 98, 99]) // added from the end by timestamp

        started[98]!()
        XCTAssertEqual(started.count, limit)
        XCTAssertEqual(started.keys.sorted(), [2, 4, 96, 97, 99]) // added from the end by timestamp
    }

    func test_real_queue() {
        let limit = 5
        let subject = ImageDownloadQueue(concurrentImagesLimit: limit,
                                         operationQueue: nil)
        var started: [Int: VoidClosure] = [:]
        var expectations: [Int: XCTestExpectation] = [:]
        var fulfilled: Set<Int> = []

        for i in 0..<100 {
            let exp = expectation(description: "\(i)")
            expectations[i] = exp

            subject.add(hash: i) {
                return .preset(.normal)
            } starter: { completion in
                exp.fulfill()
                XCTAssertTrue(fulfilled.insert(i).inserted)

                started[i] = {
                    expectations[i] = nil
                    started[i] = nil
                    completion()
                }
            }
        }

        var prev: [Int] = []
        repeat {
            let exp = expectation(description: "should added the limit")
            exp.isInverted = true
            wait(for: [exp], timeout: 0.1)

            let ids = Array(started.keys)
            XCTAssertNotEqual(ids, prev)
            XCTAssertEqual(ids.count, limit)
            wait(for: expectations[ids], timeout: 0.1)

            prev = ids
            started.values.forEach {
                $0()
            }
        } while fulfilled.count < 100

        XCTAssertEqual(fulfilled.count, 100)
    }
}

private extension Dictionary {
    subscript(keys: some Collection<Key>) -> [Value] {
        var result: [Value] = []
        for k in keys {
            if let el = self[k] {
                result.append(el)
            }
        }
        return result
    }
}
