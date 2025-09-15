import Foundation

#if swift(>=6.0)
/// Protocol for decoding image data into platform-specific image objects.
///
/// `ImageDecoding` provides a way to convert raw image data into displayable images.
/// You can implement custom decoders for specific image formats or use the built-in
/// `ImageDecoders.Default` implementation which handles common formats.
///
/// ## Usage Example
/// ```swift
/// struct CustomDecoder: ImageDecoding {
///     func decode(_ data: Data) -> Image? {
///         // Custom decoding logic for specific format
///         return decodedImage
///     }
/// }
///
/// let downloader = ImageDownloader(
///     network: network,
///     decoders: [CustomDecoder(), ImageDecoders.Default()]
/// )
/// ```
public protocol ImageDecoding: Sendable {
    func decode(_ data: Data) -> Image?
}
#else
/// Protocol for decoding image data into platform-specific image objects.
///
/// `ImageDecoding` provides a way to convert raw image data into displayable images.
/// You can implement custom decoders for specific image formats or use the built-in
/// `ImageDecoders.Default` implementation which handles common formats.
///
/// ## Usage Example
/// ```swift
/// struct CustomDecoder: ImageDecoding {
///     func decode(_ data: Data) -> Image? {
///         // Custom decoding logic for specific format
///         return decodedImage
///     }
/// }
///
/// let downloader = ImageDownloader(
///     network: network,
///     decoders: [CustomDecoder(), ImageDecoders.Default()]
/// )
/// ```
public protocol ImageDecoding {
    func decode(_ data: Data) -> Image?
}
#endif

/// Namespace for built-in and custom image decoders.
///
/// `ImageDecoders` provides a namespace for organizing image decoders and includes
/// the default implementation for common image formats.
public enum ImageDecoders {}

// MARK: - ImageDecoders.Default

public extension ImageDecoders {
    /// Default implementation of `ImageDecoding` that handles common image formats.
    ///
    /// `Default` decoder supports standard image formats like PNG, JPEG, GIF, and WebP
    /// on supported platforms. It uses the platform's native image creation methods.
    ///
    /// ## Usage Example
    /// ```swift
    /// let downloader = ImageDownloader(
    ///     network: network,
    ///     decoders: [ImageDecoders.Default()]
    /// )
    /// ```
    struct Default: ImageDecoding {
        /// Creates a new default image decoder.
        public init() {}

        /// Decodes image data into a platform-specific image object.
        ///
        /// - Parameter data: The image data to decode.
        /// - Returns: A decoded image if successful, `nil` otherwise.
        public func decode(_ data: Data) -> Image? {
            return PlatformImage(data: data)?.sdk
        }
    }
}
