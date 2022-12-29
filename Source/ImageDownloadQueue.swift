import Foundation
import NCallback
import NQueue

protocol ImageDownloadQueue {
    typealias Priority = ImageDownloadQueuePriority
    typealias Operation = ImageDownloadOperation

    func add(requestGenerator: @autoclosure @escaping () -> Callback<Image?>,
             completionCallback: Callback<Image?>,
             url: URL,
             prioritizer: @escaping (URL) -> Priority)
    func cancel(for url: URL)
}

internal enum ImageDownloadQueuePriority: Comparable {
    case preset(ImageInfo.Priority)
    case hasImageView
}

// MARK: - Impl.ImageDownloadQueue

extension Impl {
    final class ImageDownloadQueue {
        typealias Priority = ImageDownloadQueuePriority

        private struct Operation: Hashable {
            private let prioritizer: (URL) -> Priority
            let original: NImageDownloader.ImageDownloadOperation

            init(prioritizer: @escaping (URL) -> Priority,
                 original: NImageDownloader.ImageDownloadOperation) {
                self.prioritizer = prioritizer
                self.original = original
            }

            func priority() -> Priority {
                return prioritizer(original.url)
            }

            func hash(into hasher: inout Hasher) {
                hasher.combine(original.url)
            }

            static func ==(lhs: Impl.ImageDownloadQueue.Operation, rhs: Impl.ImageDownloadQueue.Operation) -> Bool {
                return lhs.original.url == rhs.original.url
            }
        }

        @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
        private var syncedOperations: [() -> Void] = []
        private var operationQueue: Queueable = Queue.custom(label: "ImageDownloadQueue.Operation",
                                                             qos: .utility,
                                                             attributes: .concurrent)
        private var scheduleQueue: Queueable = Queue.custom(label: "ImageDownloadQueue.Scheduling",
                                                            qos: .utility,
                                                            attributes: .serial)

        private let operationFactory: NImageDownloader.ImageDownloadOperationFactory
        private var scheduledOperations: [Operation] = []
        private var runningOperations: [Operation] = []
        private let maxConcurrentOperationCount: Int
        private var isScheduled: Bool = false

        init(concurrentImagesLimit: ConcurrentImagesLimit,
             operationFactory: NImageDownloader.ImageDownloadOperationFactory) {
            self.operationFactory = operationFactory

            switch concurrentImagesLimit {
            case .infinite:
                self.maxConcurrentOperationCount = .max
            case .other(let count):
                self.maxConcurrentOperationCount = max(count, 1)
            }
        }

        private func scheduleUpdate() {
            if isScheduled {
                return
            }
            isScheduled = true
            applyOperations()
        }

        private func applyOperations() {
            operationQueue.async { [weak self] in
                guard let self = self else {
                    return
                }

                for operation in self.syncedOperations {
                    operation()
                }
                self.syncedOperations = []

                if self.isScheduled {
                    self.checkQueue()
                }

                self.isScheduled = false
            }
        }

        private func checkQueue() {
            runningOperations = runningOperations.filter {
                return $0.original.state == .running
            }

            var operations = scheduledOperations
                .filter {
                    return $0.original.state == .idle
                }
                .map {
                    return (element: $0, original: $0.original, priority: $0.priority())
                }
                .sorted(by: {
                    if $0.priority == $1.priority {
                        return $0.original.timestamp >= $1.original.timestamp
                    }
                    return $0.priority > $1.priority
                })

            while !operations.isEmpty, runningOperations.count < maxConcurrentOperationCount {
                let operation = operations.removeFirst()
                runningOperations.append(operation.element)

                operation.original.start()
                    .schedule(completionIn: scheduleQueue)
                    .onComplete { [weak self] _ in
                        self?.scheduleUpdate()
                    }
            }

            scheduledOperations = operations.map(\.element)
        }
    }
}

// MARK: - Impl.ImageDownloadQueue + ImageDownloadQueue

extension Impl.ImageDownloadQueue: ImageDownloadQueue {
    func add(requestGenerator: @autoclosure @escaping () -> Callback<Image?>,
             completionCallback: Callback<Image?>,
             url: URL,
             prioritizer: @escaping (URL) -> Priority) {
        let originalOperation = operationFactory.make(requestGenerator: requestGenerator,
                                                      completionCallback: completionCallback,
                                                      url: url)
        let operation = Operation(prioritizer: prioritizer,
                                  original: originalOperation)
        syncedOperations.append {
            self.scheduledOperations.append(operation)
        }
        scheduleUpdate()
    }

    func cancel(for url: URL) {
        syncedOperations.append {
            let operations = self.scheduledOperations + self.runningOperations
            for operation in operations {
                let operation = operation.original
                if operation.state != .canceled, operation.url == url {
                    operation.cancel()
                }
            }
        }
        scheduleUpdate()
    }
}

private extension Impl.ImageDownloadQueue.Priority {
    var logDescription: String {
        switch self {
        case .preset(let priority):
            switch priority {
            case .veryLow:
                return "veryLow"
            case .low:
                return "low"
            case .normal:
                return "normal"
            case .high:
                return "high"
            case .veryHight:
                return "veryHight"
            }
        case .hasImageView:
            return "hasImageView"
        }
    }
}
