import Foundation
import NCallback
import NQueue
import UIKit

public protocol ImageProcessor {
    var name: String { get }
    func process(_ image: UIImage) -> UIImage
}

public extension ImageProcessor {
    var name: String {
        return String(reflecting: self)
    }
}

// can be used as namespace for any ImageProcessor declared in any other place of app
public enum ImageProcessors {}

public extension ImageProcessors {
    struct Composition {
        private let processors: [ImageProcessor]

        public init(processors: [ImageProcessor]) {
            self.processors = processors
        }
    }
}

extension ImageProcessors.Composition: ImageProcessor {
    public func process(_ image: UIImage) -> UIImage {
        if !processors.isEmpty {
            return processors.reduce(image) {
                return $1.process($0)
            }
        }

        return image
    }
}
