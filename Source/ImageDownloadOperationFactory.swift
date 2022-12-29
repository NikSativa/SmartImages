import Foundation
import NCallback
import NRequest

protocol ImageDownloadOperationFactory {
    func make(requestGenerator: @escaping () -> Callback<Image?>,
              completionCallback: Callback<Image?>,
              url: URL) -> ImageDownloadOperation
}

// MARK: - Impl.ImageDownloadOperationFactory

extension Impl {
    final class ImageDownloadOperationFactory {
        init() {}
    }
}

// MARK: - Impl.ImageDownloadOperationFactory + ImageDownloadOperationFactory

extension Impl.ImageDownloadOperationFactory: ImageDownloadOperationFactory {
    func make(requestGenerator: @escaping () -> Callback<Image?>,
              completionCallback: Callback<Image?>,
              url: URL) -> ImageDownloadOperation {
        return Impl.ImageDownloadOperation(requestGenerator: requestGenerator,
                                           completionCallback: completionCallback,
                                           url: url)
    }
}
