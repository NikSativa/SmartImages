import Foundation
import NSpry

@testable import NImageDownloader

public final class FakeImageDownloaderNetwork: ImageDownloaderNetwork, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case request = "request(with:cachePolicy:timeoutInterval:completion:)"
    }

    public init() {}

    public var completion: ((Result<Data, Error>) -> Void)?
    public func request(with url: URL,
                        cachePolicy: URLRequest.CachePolicy,
                        timeoutInterval: TimeInterval,
                        completion: @escaping (Result<Data, Error>) -> Void) -> ImageDownloaderTask {
        self.completion = completion
        return spryify(arguments: url, cachePolicy, timeoutInterval, completion)
    }
}
