import Foundation
import NCallback

protocol ImageDownloadOperation {
    typealias State = ImageDownloadOperationState

    var url: URL { get }
    var state: State { get }
    var timestamp: TimeInterval { get }

    func start() -> Callback<Image?>
    func cancel()
}

internal enum ImageDownloadOperationState {
    case idle
    case running
    case canceled
    case finished
}

// MARK: - Impl.ImageDownloadOperation

extension Impl {
    final class ImageDownloadOperation {
        typealias Generator = () -> Callback<Image?>
        typealias State = ImageDownloadOperationState

        private var request: Callback<Image?>?
        private let requestGenerator: Generator
        private let completionCallback: Callback<Image?>
        private let lifecycleId: UInt64

        private(set) var state: State = .idle
        let url: URL
        let timestamp: TimeInterval

        init(requestGenerator: @escaping Generator,
             completionCallback: Callback<Image?>,
             url: URL,
             date: Date = Date(),
             lifecycleId: UInt64 = .random(in: .min...UInt64.max)) {
            self.requestGenerator = requestGenerator
            self.completionCallback = completionCallback
            self.url = url
            self.lifecycleId = lifecycleId

            self.timestamp = date.timeIntervalSinceReferenceDate
        }
    }
}

// MARK: - Impl.ImageDownloadOperation + ImageDownloadOperation

extension Impl.ImageDownloadOperation: ImageDownloadOperation {
    func start() -> Callback<Image?> {
        assert(state == .idle, "should not be called twice")

        return .init { [weak self, requestGenerator, completionCallback] actual in
            guard let self = self else {
                return
            }

            if self.state == .canceled {
                return
            }

            self.state = .running

            requestGenerator()
                .assign(to: &self.request)
                .beforeComplete { [weak self] _ in
                    self?.state = .finished
                }
                .deferred { [weak self] _ in
                    self?.request = nil
                }
                .onComplete(options: .oneOff(.weakness)) { [completionCallback] image in
                    completionCallback.complete(image)
                    actual.complete(image)
                }
        }
    }

    func cancel() {
        assert(state != .canceled, "should not be called twice")
        state = .canceled
        request = nil
    }
}
