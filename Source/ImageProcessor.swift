import Foundation
import Threading

#if swift(>=6.0)
/// Protocol for processing images while they are being downloaded and decoded.
/// Ex. resizing, cropping, blurring, etc.
public protocol ImageProcessor: Sendable {
    func process(_ image: Image) -> Image
}
#else
/// Protocol for processing images while they are being downloaded and decoded.
/// Ex. resizing, cropping, blurring, etc.
public protocol ImageProcessor {
    func process(_ image: Image) -> Image
}
#endif

/// Namespace for any ImageProcessor declared in any other place of app
public enum ImageProcessors {}

// MARK: - ImageProcessors.Composition

public extension ImageProcessors {
    struct Composition {
        private let processors: [ImageProcessor]

        public init(processors: [ImageProcessor]) {
            self.processors = processors
        }
    }
}

// MARK: - ImageProcessors.Composition + ImageProcessor

extension ImageProcessors.Composition: ImageProcessor {
    public func process(_ image: Image) -> Image {
        if !processors.isEmpty {
            return processors.reduce(image) {
                return $1.process($0)
            }
        }

        return image
    }
}
