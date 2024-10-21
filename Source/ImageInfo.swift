import Foundation

/// Represents the information needed to download an image.
public struct ImageInfo {
    public let url: URL
    public let cachePolicy: URLRequest.CachePolicy?
    public let timeoutInterval: TimeInterval?
    public let processors: [ImageProcessor]
    public let priority: ImagePriority

    /// Creates a new instance of `ImageInfo`.
    /// - Parameters:
    ///  - url: The URL of the image to download.
    ///  - cachePolicy: The cache policy to use for the request. `nil`.
    ///  - timeoutInterval: The maximum time interval for the request to complete.  `nil`.
    ///  - processors: An array of processors to be applied to the image. The `processors` are applied in the order they are passed.
    ///  - priority: The priority of the image download task.
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
