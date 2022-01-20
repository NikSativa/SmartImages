import Foundation
import NCallback
import UIKit

protocol ImageDownloadOperation {
    typealias State = ImageDownloadOperationState

    var url: URL { get }
    var state: State { get }
    var timestamp: TimeInterval { get }

    func start() -> Callback<UIImage?>
    func cancel()
}

internal enum ImageDownloadOperationState {
    case idle
    case running
    case canceled
    case finished
}

extension Impl {
    final class ImageDownloadOperation {
        typealias Generator = () -> Callback<UIImage?>
        typealias State = ImageDownloadOperationState

        private var request: Callback<UIImage?>?
        private let requestGenerator: Generator
        private let completionCallback: Callback<UIImage?>
        private let lifecycleId: UInt64

        private(set) var state: State = .idle
        let url: URL
        let timestamp: TimeInterval

        init(requestGenerator: @escaping Generator,
             completionCallback: Callback<UIImage?>,
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

extension Impl.ImageDownloadOperation: ImageDownloadOperation {
    func start() -> Callback<UIImage?> {
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
