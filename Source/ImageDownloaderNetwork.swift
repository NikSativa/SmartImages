import Foundation

#if swift(>=6.0)
/// A protocol defining the network layer for downloading images asynchronously.
///
/// Implement this protocol to create a network service for downloading images from URLs.
public protocol ImageDownloaderNetwork: Sendable {
    /// Typealias for the completion closure when downloading an image.
    typealias ResultCompletion = @Sendable (Result<Data, Error>) -> Void

    /// Initiates a network request to download an image from the specified URL.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to download.
    ///   - cachePolicy: The cache policy to use for the request. `nil` if the policy is not specified when calling `ImageDownloading` interface.
    ///   - timeoutInterval: The maximum time interval for the request to complete.  `nil` if the timeout interval is not specified when calling `ImageDownloading` interface.
    ///   - completion: A closure that is called when the request completes, providing the downloaded image data or an error.
    /// - Returns: An `ImageDownloaderTask` representing the download task.
    func request(with url: URL,
                 cachePolicy: URLRequest.CachePolicy?,
                 timeoutInterval: TimeInterval?,
                 completion: @escaping ResultCompletion) -> ImageDownloaderTask
}
#else
/// A protocol defining the network layer for downloading images asynchronously.
///
/// Implement this protocol to create a network service for downloading images from URLs.
public protocol ImageDownloaderNetwork {
    /// Typealias for the completion closure when downloading an image.
    typealias ResultCompletion = (Result<Data, Error>) -> Void

    /// Initiates a network request to download an image from the specified URL.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to download.
    ///   - cachePolicy: The cache policy to use for the request. `nil` if the policy is not specified when calling `ImageDownloading` interface.
    ///   - timeoutInterval: The maximum time interval for the request to complete.  `nil` if the timeout interval is not specified when calling `ImageDownloading` interface.
    ///   - completion: A closure that is called when the request completes, providing the downloaded image data or an error.
    /// - Returns: An `ImageDownloaderTask` representing the download task.
    func request(with url: URL,
                 cachePolicy: URLRequest.CachePolicy?,
                 timeoutInterval: TimeInterval?,
                 completion: @escaping ResultCompletion) -> ImageDownloaderTask
}
#endif
