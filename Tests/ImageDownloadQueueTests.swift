#if canImport(SpryMacroAvailable) && swift(>=6.0)
import Foundation
import SpryKit
import Threading
import XCTest
@testable import SmartImages

final class ImageDownloadQueueTests: XCTestCase {
    /// `@Sendable` in `SmartImages.VoidClosure` is breaking the cast
    private typealias VoidClosure = () -> Void

    func test_unlimited() {
        let queue = FakeQueueable()
        queue.stub(.asyncWithExecute).andDo { args in
            if let task = args[0] as? VoidClosure {
                task()
            }
            return ()
        }

        let subject = ImageDownloadQueue(concurrentImagesLimit: nil,
                                         operatioThreading: queue)
        let started: SendableResult<[Int]> = .init(value: [])

        for i in 0..<100 {
            subject.add(hash: i) {
                return .preset(.normal)
            } starter: { _ in
                started.value.append(i)
            }
            queue.asyncWorkItem?()
        }

        XCTAssertEqual(started.value.count, 100)
    }

    func test_limited() {
        let limit = 5
        let queue = FakeQueueable()
        queue.stub(.asyncWithExecute).andDo { args in
            if let task = args[0] as? VoidClosure {
                task()
            }
            return ()
        }

        let subject = ImageDownloadQueue(concurrentImagesLimit: limit,
                                         operatioThreading: queue)
        let started: SendableResult<[Int: VoidClosure]> = .init(value: [:])

        for i in 0..<100 {
            subject.add(hash: i) {
                return .preset(.normal)
            } starter: { completion in
                started.value[i] = {
                    started.value[i] = nil
                    completion()
                } as VoidClosure
            }
        }

        subject.add(hash: "google.com/hasImageView") {
            return .hasImageView
        } starter: { completion in
            started.value[111] = {
                started.value[111] = nil
                completion()
            } as VoidClosure
        }

        XCTAssertEqual(started.value.count, limit)
        XCTAssertEqual(started.value.keys.sorted(), [0, 1, 2, 3, 4])

        started.value[0]!()
        XCTAssertEqual(started.value.count, limit)
        XCTAssertEqual(started.value.keys.sorted(), [1, 2, 3, 4, 111]) // added by priority 'hasImageView'

        started.value[1]!()
        XCTAssertEqual(started.value.count, limit)
        XCTAssertEqual(started.value.keys.sorted(), [2, 3, 4, 99, 111]) // added from the end by timestamp

        started.value[111]!()
        XCTAssertEqual(started.value.count, limit)
        XCTAssertEqual(started.value.keys.sorted(), [2, 3, 4, 98, 99]) // added from the end by timestamp

        started.value[3]!()
        XCTAssertEqual(started.value.count, limit)
        XCTAssertEqual(started.value.keys.sorted(), [2, 4, 97, 98, 99]) // added from the end by timestamp

        started.value[98]!()
        XCTAssertEqual(started.value.count, limit)
        XCTAssertEqual(started.value.keys.sorted(), [2, 4, 96, 97, 99]) // added from the end by timestamp
    }

    func test_real_queue() {
        let limit = 5
        let subject = ImageDownloadQueue(concurrentImagesLimit: limit,
                                         operatioThreading: nil)
        let expectations: SendableResult<[Int: XCTestExpectation]> = .init(value: [:])
        let started: SendableResult<[Int: () -> Void]> = .init(value: [:])
        let fulfilled: SendableResult<Set<Int>> = .init(value: [])

        for i in 0..<100 {
            let exp = expectation(description: "\(i)")
            expectations.value[i] = exp

            subject.add(hash: i) {
                return .preset(.normal)
            } starter: { completion in
                exp.fulfill()
                XCTAssertTrue(fulfilled.value.insert(i).inserted)

                started.value[i] = {
                    expectations.value[i] = nil
                    started.value[i] = nil
                    completion()
                }
            }
        }

        var prev: [Int] = []
        repeat {
            let exp = expectation(description: "should added the limit")
            exp.isInverted = true
            wait(for: [exp], timeout: 0.1)

            let ids = Array(started.value.keys)
            XCTAssertNotEqual(ids, prev)
            XCTAssertEqual(ids.count, limit)
            wait(for: expectations.value[ids], timeout: 0.1)

            prev = ids
            for value in started.value.values {
                value()
            }
        } while fulfilled.value.count < 100

        XCTAssertEqual(fulfilled.value.count, 100)
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
#endif
