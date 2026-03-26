import Foundation
import Threading

/// Priority level for operations in the ``ImageDownloadQueue``.
///
/// Operations with `.hasImageView` priority are always preferred over `.preset` operations,
/// ensuring that visible image views receive their images first.
public enum FetchQueueingPriority: Comparable {
    case preset(FetchPriority)
    case hasImageView
}

#if swift(>=6.0)
public protocol ImageQueueScheduling: Sendable {
    typealias Prioritizer = @Sendable () -> FetchQueueingPriority
    typealias Starter = @Sendable (_ completion: @escaping VoidClosure) -> Void

    func add(hash: AnyHashable,
             prioritizer: @escaping Prioritizer,
             starter: @escaping Starter)
}
#else
public protocol ImageQueueScheduling {
    typealias Prioritizer = () -> FetchQueueingPriority
    typealias Starter = (_ completion: @escaping VoidClosure) -> Void

    func add(hash: AnyHashable,
             prioritizer: @escaping Prioritizer,
             starter: @escaping Starter)
}
#endif

/// A priority queue that manages concurrent image download operations.
///
/// Limits the number of simultaneously running downloads and prioritizes operations
/// based on their ``FetchQueueingPriority``. Higher priority operations are started first.
public final class ImageDownloadQueue {
    typealias Priority = FetchQueueingPriority

    private let mutex: Locking = AnyLock.pthread(.recursive)
    private let operationThreading: Queueable

    private var scheduledOperations: [Operation] = []
    private var runningOperations: [Operation] = []
    private let maxConcurrentOperationCount: Int
    private var isScheduled: Bool = false

    /// The open interface `operationThreading` is for testing purposes only.
    public init(concurrentImagesLimit limit: Int?, operationThreading: Queueable? = nil) {
        self.operationThreading = operationThreading ?? Queue.custom(label: "ImageDownloadQueue.Operation",
                                                                     qos: .utility,
                                                                     attributes: .serial)
        self.maxConcurrentOperationCount = limit.map {
            return max($0, 1)
        } ?? .max
    }

    private func scheduleUpdate() {
        if isScheduled {
            return
        }
        mutex.sync {
            isScheduled = true
        }

        operationThreading.async { [weak self] in
            self?.checkQueue()

            self?.mutex.syncUnchecked {
                self?.isScheduled = false
            }
        }
    }

    private func checkQueue() {
        mutex.sync {
            var operations = scheduledOperations
                .sorted(by: {
                    let a = $0.priority()
                    let b = $1.priority()
                    if a == b {
                        return $0.timestamp >= $1.timestamp
                    }
                    return a > b
                })

            while !operations.isEmpty, runningOperations.count < maxConcurrentOperationCount {
                let operation = operations.removeFirst()
                runningOperations.append(operation)
                operation.starter { [self] in
                    operationThreading.async { [self] in
                        operationDidFinished(operation)
                    }
                }
            }

            scheduledOperations = operations
        }
    }

    private func operationDidFinished(_ operation: Operation) {
        mutex.sync {
            runningOperations.removeAll { cached in
                return cached == operation
            }
        }
        scheduleUpdate()
    }
}

// MARK: - ImageQueueScheduling

extension ImageDownloadQueue: ImageQueueScheduling {
    public func add(hash: AnyHashable,
                    prioritizer: @escaping Prioritizer,
                    starter: @escaping Starter) {
        mutex.syncUnchecked {
            let operation = Operation(hash: hash, prioritizer: prioritizer, starter: starter)
            scheduledOperations.append(operation)
        }
        scheduleUpdate()
    }
}

// MARK: - ImageDownloadQueue.Operation

private extension ImageDownloadQueue {
    struct Operation: Equatable {
        private let prioritizer: ImageQueueScheduling.Prioritizer

        let hash: AnyHashable
        let starter: ImageQueueScheduling.Starter
        let timestamp: TimeInterval = Date().timeIntervalSinceReferenceDate

        init(hash: AnyHashable,
             prioritizer: @escaping ImageQueueScheduling.Prioritizer,
             starter: @escaping ImageQueueScheduling.Starter) {
            self.hash = hash
            self.prioritizer = prioritizer
            self.starter = starter
        }

        func priority() -> Priority {
            return prioritizer()
        }

        static func ==(lhs: Operation, rhs: Operation) -> Bool {
            return lhs.hash == rhs.hash
        }
    }
}

#if swift(>=6.0)
extension ImageDownloadQueue: @unchecked Sendable {}
extension ImageDownloadQueue.Operation: @unchecked Sendable {}
extension FetchQueueingPriority: Sendable {}
#endif
