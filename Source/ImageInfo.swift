import Foundation

public struct ImageInfo {
    public let url: URL
    public let cachePolicy: URLRequest.CachePolicy
    public let timeoutInterval: TimeInterval
    public let processors: [ImageProcessor]
    public let priority: ImagePriority

    public init(url: URL,
                cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                timeoutInterval: TimeInterval = 60,
                processors: [ImageProcessor] = [],
                priority: ImagePriority = .default) {
        self.url = url
        self.cachePolicy = cachePolicy
        self.timeoutInterval = timeoutInterval
        self.processors = processors
        self.priority = priority
    }
}
