import Foundation
import NQueue

internal enum ImageDownloadQueuePriority: Comparable {
    case preset(ImagePriority)
    case hasImageView
}

internal protocol ImageDownloadQueueing {
    func add(hash: AnyHashable,
             prioritizer: @escaping () -> ImageDownloadQueuePriority,
             starter: @escaping (_ completion: @escaping VoidClosure) -> Void)
}

internal final class ImageDownloadQueue {
    typealias Priority = ImageDownloadQueuePriority

    private let mutex: Mutexing = Mutex.pthread(.recursive)
    private let operationQueue: Queueable

    private var scheduledOperations: [Operation] = []
    private var runningOperations: [Operation] = []
    private let maxConcurrentOperationCount: Int
    private var isScheduled: Bool = false

    init(concurrentImagesLimit limit: Int?,
         operationQueue: Queueable? = nil) {
        self.operationQueue = operationQueue ?? Queue.custom(label: "ImageDownloadQueue.Operation",
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

        operationQueue.async { [weak self] in
            self?.checkQueue()

            self?.mutex.sync {
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
                    operationQueue.async { [self] in
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
             prioritizer: @escaping () -> Priority,
             starter: @escaping (_ completion: @escaping VoidClosure) -> Void) {
        mutex.sync {
            let operation = Operation(hash: hash, prioritizer: prioritizer, starter: starter)
            scheduledOperations.append(operation)
        }
        scheduleUpdate()
    }
}

// MARK: - ImageDownloadQueue.Operation

private extension ImageDownloadQueue {
    struct Operation: Equatable {
        private let prioritizer: () -> Priority

        let hash: AnyHashable
        let starter: (@escaping VoidClosure) -> Void
        let timestamp: TimeInterval = Date().timeIntervalSinceReferenceDate

        init(hash: AnyHashable,
             prioritizer: @escaping () -> Priority,
             starter: @escaping (@escaping VoidClosure) -> Void) {
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
