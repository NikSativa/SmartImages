import Foundation

/// Configuration information for downloading and processing an image.
///
/// `ImageRequest` encapsulates all the parameters needed to download an image, including URL, cache policy,
/// timeout settings, image processors, and download priority. This allows for fine-grained control over
/// how images are downloaded and processed.
///
/// ## Usage Example
/// ```swift
/// let info = ImageRequest(
///     url: URL(string: "https://example.com/image.jpg")!,
///     cachePolicy: .returnCacheDataElseLoad,
///     timeoutInterval: 30.0,
///     processors: [ImageProcessors.Resize(size: CGSize(width: 200, height: 200))],
///     priority: .high
/// )
/// ```
public struct ImageRequest {
    public let url: URL
    public let cachePolicy: URLRequest.CachePolicy?
    public let timeoutInterval: TimeInterval?
    public let processors: [ImageProcessor]
    public let priority: FetchPriority

    /// Creates a new `ImageRequest` instance with the specified parameters.
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
                priority: FetchPriority = .default) {
        self.url = url
        self.cachePolicy = cachePolicy
        self.timeoutInterval = timeoutInterval
        self.processors = processors
        self.priority = priority
    }
}

extension ImageRequest: Hashable {
    public static func ==(lhs: ImageRequest, rhs: ImageRequest) -> Bool {
        return lhs.url == rhs.url
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}

#if swift(>=6.0)
extension ImageRequest: Sendable {}
#endif
