import Foundation
import NCallback
import UIKit

protocol ImageProcessing {
    func process(_ image: UIImage,
                 processors: [ImageProcessor]) -> Callback<UIImage>
}

extension Impl {
    struct ImageProcessing {
        init() {
        }
    }
}

extension Impl.ImageProcessing: ImageProcessing {
    func process(_ image: UIImage,
                 processors: [ImageProcessor]) -> Callback<UIImage> {
        return .init { actual in
            let composition = ImageProcessors.Composition(processors: processors)
            let processedImage = composition.process(image)
            actual.complete(processedImage)
        }
    }
}
