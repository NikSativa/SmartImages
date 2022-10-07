import Foundation
import NCallback

protocol ImageProcessing {
    func process(_ image: Image,
                 processors: [ImageProcessor]) -> Callback<Image>
}

extension Impl {
    struct ImageProcessing {
        init() {}
    }
}

extension Impl.ImageProcessing: ImageProcessing {
    func process(_ image: Image,
                 processors: [ImageProcessor]) -> Callback<Image> {
        return .init { actual in
            let composition = ImageProcessors.Composition(processors: processors)
            let processedImage = composition.process(image)
            actual.complete(processedImage)
        }
    }
}
