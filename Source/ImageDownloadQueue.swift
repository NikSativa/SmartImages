import Foundation
import Threading

internal enum ImageDownloadQueuePriority: Comparable {
    case preset(ImagePriority)
    case hasImageView
}

#if swift(>=6.0)
internal protocol ImageDownloadQueueing: Sendable {
    typealias Prioritizer = @Sendable () -> ImageDownloadQueuePriority
    typealias Starter = @Sendable (_ completion: @escaping VoidClosure) -> Void

    func add(hash: AnyHashable,
             prioritizer: @escaping Prioritizer,
             starter: @escaping Starter)
}
#else
internal protocol ImageDownloadQueueing {
    typealias Prioritizer = () -> ImageDownloadQueuePriority
    typealias Starter = (_ completion: @escaping VoidClosure) -> Void

    func add(hash: AnyHashable,
             prioritizer: @escaping Prioritizer,
             starter: @escaping Starter)
}
#endif

internal final class ImageDownloadQueue {
    typealias Priority = ImageDownloadQueuePriority

    private let mutex: Locking = AnyLock.pthread(.recursive)
    private let operatioThreading: Queueable

    private var scheduledOperations: [Operation] = []
    private var runningOperations: [Operation] = []
    private let maxConcurrentOperationCount: Int
    private var isScheduled: Bool = false

    /// The open interface `operatioThreading` is for testing purposes only.
    init(concurrentImagesLimit limit: Int?, operatioThreading: Queueable? = nil) {
        self.operatioThreading = operatioThreading ?? Queue.custom(label: "ImageDownloadQueue.Operation",
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

        operatioThreading.async { [weak self] in
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
                    operatioThreading.async { [self] in
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

// MARK: - ImageDownloadQueueing

extension ImageDownloadQueue: ImageDownloadQueueing {
    func add(hash: AnyHashable,
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
        private let prioritizer: ImageDownloadQueueing.Prioritizer

        let hash: AnyHashable
        let starter: ImageDownloadQueueing.Starter
        let timestamp: TimeInterval = Date().timeIntervalSinceReferenceDate

        init(hash: AnyHashable,
             prioritizer: @escaping ImageDownloadQueueing.Prioritizer,
             starter: @escaping ImageDownloadQueueing.Starter) {
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
extension ImageDownloadQueuePriority: Sendable {}
#endif
