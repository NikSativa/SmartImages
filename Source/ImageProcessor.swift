import Foundation
import Threading

#if swift(>=6.0)
/// Protocol for processing images during download and decode operations.
///
/// `ImageProcessor` allows you to transform images before they are displayed, such as resizing,
/// cropping, applying filters, or any other image manipulation. Processors are applied in the
/// order they are provided in the `ImageInfo.processors` array.
///
/// ## Usage Example
/// ```swift
/// struct ResizeProcessor: ImageProcessor {
///     let targetSize: CGSize
///
///     func process(_ image: Image) -> Image {
///         // Resize image to target size
///         return resizedImage
///     }
/// }
///
/// let info = ImageInfo(
///     url: imageURL,
///     processors: [ResizeProcessor(targetSize: CGSize(width: 200, height: 200))]
/// )
/// ```
public protocol ImageProcessor: Sendable {
    func process(_ image: Image) -> Image
}
#else
/// Protocol for processing images during download and decode operations.
///
/// `ImageProcessor` allows you to transform images before they are displayed, such as resizing,
/// cropping, applying filters, or any other image manipulation. Processors are applied in the
/// order they are provided in the `ImageInfo.processors` array.
///
/// ## Usage Example
/// ```swift
/// struct ResizeProcessor: ImageProcessor {
///     let targetSize: CGSize
///
///     func process(_ image: Image) -> Image {
///         // Resize image to target size
///         return resizedImage
///     }
/// }
///
/// let info = ImageInfo(
///     url: imageURL,
///     processors: [ResizeProcessor(targetSize: CGSize(width: 200, height: 200))]
/// )
/// ```
public protocol ImageProcessor {
    func process(_ image: Image) -> Image
}
#endif

/// Namespace for built-in and custom image processors.
///
/// `ImageProcessors` provides a namespace for organizing image processors and includes
/// utility implementations like `Composition` for chaining multiple processors.
public enum ImageProcessors {}

// MARK: - ImageProcessors.Composition

public extension ImageProcessors {
    /// A processor that chains multiple processors together, applying them in sequence.
    ///
    /// `Composition` allows you to combine multiple image processors and apply them
    /// in the order they are provided. Each processor receives the output of the
    /// previous processor.
    ///
    /// ## Usage Example
    /// ```swift
    /// let processors = [
    ///     ResizeProcessor(size: CGSize(width: 200, height: 200)),
    ///     BlurProcessor(radius: 2.0)
    /// ]
    /// let composition = ImageProcessors.Composition(processors: processors)
    /// ```
    struct Composition {
        private let processors: [ImageProcessor]

        /// Creates a composition processor with the specified processors.
        ///
        /// - Parameter processors: Array of processors to apply in sequence.
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
