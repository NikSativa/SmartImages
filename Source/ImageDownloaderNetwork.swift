import Foundation

public protocol ImageDownloaderNetwork {
    func request(with url: URL,
                 cachePolicy: URLRequest.CachePolicy,
                 timeoutInterval: TimeInterval,
                 completion: @escaping (Result<Data, Error>) -> Void) -> ImageDownloaderTask
}
