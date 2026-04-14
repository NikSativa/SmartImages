import Foundation

#if swift(>=6.0)
/// A protocol defining the network layer for downloading images asynchronously.
///
/// Implement this protocol to create a network service for downloading images from URLs.
public protocol ImageNetworkProvider: Sendable {
    /// Typealias for the completion closure when downloading an image.
    typealias ResultCompletion = @Sendable (Result<Data, Error>) -> Void

    /// Initiates a network request to download an image from the specified URL.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to download.
    ///   - cachePolicy: The cache policy to use for the request. `nil` if the policy is not specified when calling `ImageFetching` interface.
    ///   - timeoutInterval: The maximum time interval for the request to complete.  `nil` if the timeout interval is not specified when calling `ImageFetching` interface.
    ///   - completion: A closure that is called when the request completes, providing the downloaded image data or an error.
    /// - Returns: An `ImageNetworkTask` representing the download task.
    func request(with url: URL,
                 cachePolicy: URLRequest.CachePolicy?,
                 timeoutInterval: TimeInterval?,
                 completion: @escaping ResultCompletion) -> ImageNetworkTask
}

public extension ImageNetworkProvider {
    /// Initiates a network request to download an image, with optional HTTP headers.
    ///
    /// Default implementation forwards to `request(with:cachePolicy:timeoutInterval:completion:)`,
    /// dropping headers. Override to honour `headers`.
    func request(with url: URL,
                 cachePolicy: URLRequest.CachePolicy?,
                 timeoutInterval: TimeInterval?,
                 headers: [String: String]?,
                 completion: @escaping ResultCompletion) -> ImageNetworkTask {
        return request(with: url,
                       cachePolicy: cachePolicy,
                       timeoutInterval: timeoutInterval,
                       completion: completion)
    }
}
#else
/// A protocol defining the network layer for downloading images asynchronously.
///
/// Implement this protocol to create a network service for downloading images from URLs.
public protocol ImageNetworkProvider {
    /// Typealias for the completion closure when downloading an image.
    typealias ResultCompletion = (Result<Data, Error>) -> Void

    /// Initiates a network request to download an image from the specified URL.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to download.
    ///   - cachePolicy: The cache policy to use for the request. `nil` if the policy is not specified when calling `ImageFetching` interface.
    ///   - timeoutInterval: The maximum time interval for the request to complete.  `nil` if the timeout interval is not specified when calling `ImageFetching` interface.
    ///   - completion: A closure that is called when the request completes, providing the downloaded image data or an error.
    /// - Returns: An `ImageNetworkTask` representing the download task.
    func request(with url: URL,
                 cachePolicy: URLRequest.CachePolicy?,
                 timeoutInterval: TimeInterval?,
                 completion: @escaping ResultCompletion) -> ImageNetworkTask
}

public extension ImageNetworkProvider {
    /// Initiates a network request to download an image, with optional HTTP headers.
    ///
    /// Default implementation forwards to `request(with:cachePolicy:timeoutInterval:completion:)`,
    /// dropping headers. Override to honour `headers`.
    func request(with url: URL,
                 cachePolicy: URLRequest.CachePolicy?,
                 timeoutInterval: TimeInterval?,
                 headers: [String: String]?,
                 completion: @escaping ResultCompletion) -> ImageNetworkTask {
        return request(with: url,
                       cachePolicy: cachePolicy,
                       timeoutInterval: timeoutInterval,
                       completion: completion)
    }
}
#endif
