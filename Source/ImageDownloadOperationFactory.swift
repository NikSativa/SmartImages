import Foundation
import NCallback
import NRequest
import UIKit

protocol ImageDownloadOperationFactory {
    func make(requestGenerator: @escaping () -> Callback<UIImage?>,
              completionCallback: Callback<UIImage?>,
              url: URL) -> ImageDownloadOperation
}

extension Impl {
    final class ImageDownloadOperationFactory {
        init() {
        }
    }
}

extension Impl.ImageDownloadOperationFactory: ImageDownloadOperationFactory {
    func make(requestGenerator: @escaping () -> Callback<UIImage?>,
              completionCallback: Callback<UIImage?>,
              url: URL) -> ImageDownloadOperation {
        return Impl.ImageDownloadOperation(requestGenerator: requestGenerator,
                                           completionCallback: completionCallback,
                                           url: url)
    }
}
