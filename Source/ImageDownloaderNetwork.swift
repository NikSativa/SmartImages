import Foundation

#if swift(>=6.0)
public protocol ImageDownloaderNetwork: Sendable {
    func request(with url: URL,
                 cachePolicy: URLRequest.CachePolicy,
                 timeoutInterval: TimeInterval,
                 completion: @escaping @Sendable (Result<Data, Error>) -> Void) -> ImageDownloaderTask
}
#else
public protocol ImageDownloaderNetwork {
    func request(with url: URL,
                 cachePolicy: URLRequest.CachePolicy,
                 timeoutInterval: TimeInterval,
                 completion: @escaping (Result<Data, Error>) -> Void) -> ImageDownloaderTask
}
#endif
