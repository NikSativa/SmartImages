import Foundation
import NCallback
import NRequest

protocol ImageDownloadOperationFactory {
    func make(requestGenerator: @escaping () -> Callback<Image?>,
              completionCallback: Callback<Image?>,
              url: URL) -> ImageDownloadOperation
}

extension Impl {
    final class ImageDownloadOperationFactory {
        init() {}
    }
}

extension Impl.ImageDownloadOperationFactory: ImageDownloadOperationFactory {
    func make(requestGenerator: @escaping () -> Callback<Image?>,
              completionCallback: Callback<Image?>,
              url: URL) -> ImageDownloadOperation {
        return Impl.ImageDownloadOperation(requestGenerator: requestGenerator,
                                           completionCallback: completionCallback,
                                           url: url)
    }
}
