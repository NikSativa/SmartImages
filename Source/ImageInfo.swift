import Foundation

/// Configuration information for downloading and processing an image.
///
/// `ImageInfo` encapsulates all the parameters needed to download an image, including URL, cache policy,
/// timeout settings, image processors, and download priority. This allows for fine-grained control over
/// how images are downloaded and processed.
///
/// ## Usage Example
/// ```swift
/// let info = ImageInfo(
///     url: URL(string: "https://example.com/image.jpg")!,
///     cachePolicy: .returnCacheDataElseLoad,
///     timeoutInterval: 30.0,
///     processors: [ImageProcessors.Resize(size: CGSize(width: 200, height: 200))],
///     priority: .high
/// )
/// ```
public struct ImageInfo {
    public let url: URL
    public let cachePolicy: URLRequest.CachePolicy?
    public let timeoutInterval: TimeInterval?
    public let processors: [ImageProcessor]
    public let priority: ImagePriority

    /// Creates a new `ImageInfo` instance with the specified parameters.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to download.
    ///   - cachePolicy: The cache policy for the network request. If `nil`, uses the default cache policy.
    ///   - timeoutInterval: Maximum time in seconds for the download to complete. If `nil`, uses default timeout.
    ///   - processors: Array of image processors to apply to the downloaded image. Processors are applied in order.
    ///   - priority: Download priority that affects the order in which images are downloaded.
    public init(url: URL,
                cachePolicy: URLRequest.CachePolicy? = nil,
                timeoutInterval: TimeInterval? = nil,
                processors: [ImageProcessor] = [],
                priority: ImagePriority = .default) {
        self.url = url
        self.cachePolicy = cachePolicy
        self.timeoutInterval = timeoutInterval
        self.processors = processors
        self.priority = priority
    }
}

#if swift(>=6.0)
extension ImageInfo: Sendable {}
#endif
