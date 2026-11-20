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
                                         operationThreading: queue)
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
                                         operationThreading: queue)
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

        started.value[0]?()
        XCTAssertEqual(started.value.count, limit)
        XCTAssertEqual(started.value.keys.sorted(), [1, 2, 3, 4, 111]) // added by priority 'hasImageView'

        started.value[1]?()
        XCTAssertEqual(started.value.count, limit)
        XCTAssertEqual(started.value.keys.sorted(), [2, 3, 4, 99, 111]) // added from the end by timestamp

        started.value[111]?()
        XCTAssertEqual(started.value.count, limit)
        XCTAssertEqual(started.value.keys.sorted(), [2, 3, 4, 98, 99]) // added from the end by timestamp

        started.value[3]?()
        XCTAssertEqual(started.value.count, limit)
        XCTAssertEqual(started.value.keys.sorted(), [2, 4, 97, 98, 99]) // added from the end by timestamp

        started.value[98]?()
        XCTAssertEqual(started.value.count, limit)
        XCTAssertEqual(started.value.keys.sorted(), [2, 4, 96, 97, 99]) // added from the end by timestamp
    }

    func test_real_queue() {
        let limit = 5
        let subject = ImageDownloadQueue(concurrentImagesLimit: limit,
                                         operationThreading: nil)
        let expectations = AtomicValue<[Int: XCTestExpectation]>(wrappedValue: [:])
        let started = AtomicValue<[Int: () -> Void]>(wrappedValue: [:])
        let fulfilled = AtomicValue<Set<Int>>(wrappedValue: [])

        for i in 0..<100 {
            let exp = expectation(description: "\(i)")
            expectations.syncUnchecked { map in
                map[i] = exp
            }

            subject.add(hash: i) {
                return .preset(.normal)
            } starter: { completion in
                exp.fulfill()
                XCTAssertTrue(fulfilled.syncUnchecked { set in
                    return set.insert(i).inserted
                })

                started.syncUnchecked { map in
                    map[i] = {
                        expectations.syncUnchecked { map in
                            map[i] = nil
                        }
                        started.syncUnchecked { map in
                            map[i] = nil
                        }
                        completion()
                    }
                }
            }
        }

        var prev: [Int] = []
        repeat {
            let exp = expectation(description: "should added the limit")
            exp.isInverted = true
            wait(for: [exp], timeout: 0.1)

            let ids = Array(started.wrappedValue.keys)
            XCTAssertNotEqual(ids, prev)
            XCTAssertEqual(ids.count, limit)
            wait(for: expectations.wrappedValue[ids], timeout: 0.1)

            prev = ids
            for value in started.wrappedValue.values {
                value()
            }
        } while fulfilled.wrappedValue.count < 100

        XCTAssertEqual(fulfilled.wrappedValue.count, 100)
    }

    func test_add_that_waits_for_a_running_pass_gets_its_own_pass() {
        let queue = FakeQueueable()
        let pendingWork = AtomicValue<[VoidClosure]>(wrappedValue: [])
        queue.stub(.asyncWithExecute).andDo { args in
            if let task = args[0] as? VoidClosure {
                pendingWork.syncUnchecked { pending in
                    pending.append(task)
                }
            }
            return ()
        }

        let subject = ImageDownloadQueue(concurrentImagesLimit: nil,
                                         operationThreading: queue)
        let startedHashes = AtomicValue<[Int]>(wrappedValue: [])
        let firstStarterEntered = DispatchSemaphore(value: 0)
        let firstStarterRelease = DispatchSemaphore(value: 0)
        let firstPassFinished = DispatchSemaphore(value: 0)
        let secondAddStarted = DispatchSemaphore(value: 0)
        let secondAddReturned = DispatchSemaphore(value: 0)

        subject.add(hash: 1) {
            return .preset(.normal)
        } starter: { _ in
            startedHashes.syncUnchecked { hashes in
                hashes.append(1)
            }
            firstStarterEntered.signal()
            _ = firstStarterRelease.wait(timeout: .now() + 10)
        }

        let firstPass = SendableResult(value: takeWork(from: pendingWork))
        XCTAssertEqual(firstPass.value.count, 1)
        Thread.detachNewThread {
            for work in firstPass.value {
                work()
            }
            firstPassFinished.signal()
        }
        XCTAssertEqual(firstStarterEntered.wait(timeout: .now() + 10), .success)

        Thread.detachNewThread {
            secondAddStarted.signal()
            subject.add(hash: 2) {
                return .preset(.normal)
            } starter: { _ in
                startedHashes.syncUnchecked { hashes in
                    hashes.append(2)
                }
            }
            secondAddReturned.signal()
        }
        XCTAssertEqual(secondAddStarted.wait(timeout: .now() + 10), .success)

        firstStarterRelease.signal()
        XCTAssertEqual(firstPassFinished.wait(timeout: .now() + 10), .success)
        XCTAssertEqual(secondAddReturned.wait(timeout: .now() + 10), .success)
        XCTAssertEqual(startedHashes.wrappedValue, [1])

        let secondPass = takeWork(from: pendingWork)
        XCTAssertEqual(secondPass.count, 1)
        for work in secondPass {
            work()
        }

        XCTAssertEqual(startedHashes.wrappedValue, [1, 2])
    }

    func test_concurrent_adds_start_every_operation_once_within_the_limit() {
        let limit = 4
        let operationCount = 1000
        let operationQueue = DispatchQueue(label: "ImageDownloadQueueTests.operation")
        let completionQueue = DispatchQueue(label: "ImageDownloadQueueTests.completion", attributes: .concurrent)
        let queue = FakeQueueable()
        queue.stub(.asyncWithExecute).andDo { args in
            if let task = args[0] as? VoidClosure {
                let work = SendableResult(value: task)
                operationQueue.async {
                    work.value()
                }
            }
            return ()
        }

        let subject = ImageDownloadQueue(concurrentImagesLimit: limit,
                                         operationThreading: queue)
        let startCounts = AtomicValue<[Int: Int]>(wrappedValue: [:])
        let runningCounts = AtomicValue<(current: Int, max: Int)>(wrappedValue: (current: 0, max: 0))
        let completions = DispatchGroup()
        let everyStarterCalled = expectation(description: "every starter is called")
        everyStarterCalled.expectedFulfillmentCount = operationCount

        DispatchQueue.concurrentPerform(iterations: operationCount) { index in
            subject.add(hash: index) {
                return .preset(.normal)
            } starter: { completion in
                startCounts.syncUnchecked { counts in
                    counts[index, default: 0] += 1
                }
                runningCounts.syncUnchecked { counts in
                    counts.current += 1
                    counts.max = max(counts.max, counts.current)
                }
                completions.enter()
                completionQueue.async {
                    runningCounts.syncUnchecked { counts in
                        counts.current -= 1
                    }
                    completion()
                    completions.leave()
                }
                everyStarterCalled.fulfill()
            }
        }

        wait(for: [everyStarterCalled], timeout: 10)
        XCTAssertEqual(completions.wait(timeout: .now() + 10), .success)
        operationQueue.sync {}
        operationQueue.sync {}

        let counts = startCounts.wrappedValue
        XCTAssertEqual(counts.count, operationCount)
        XCTAssertEqual(counts.filter { $0.value != 1 }.count, 0)
        XCTAssertLessThanOrEqual(runningCounts.wrappedValue.max, limit)
    }

    private func takeWork(from pendingWork: AtomicValue<[VoidClosure]>) -> [VoidClosure] {
        return pendingWork.syncUnchecked { pending in
            let work = pending
            pending = []
            return work
        }
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
