import Foundation
import SmartImages
import SpryKit

public final class FakeImageDownloaderNetwork: ImageDownloaderNetwork, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case request = "request(with:cachePolicy:timeoutInterval:completion:finishedOrCancelled:)"
    }

    public init() {}

    public var completion: ((Result<Data, Error>) -> Void)?
    public func request(with url: URL,
                        cachePolicy: URLRequest.CachePolicy?,
                        timeoutInterval: TimeInterval?,
                        completion: @escaping ResultCompletion,
                        finishedOrCancelled finished: FinishedCompletion?) -> ImageDownloaderTask {
        self.completion = completion
        return spryify(arguments: url, cachePolicy, timeoutInterval, completion, finished)
    }
}

#if swift(>=6.0)
extension FakeImageDownloaderNetwork: @unchecked Sendable {}
#endif
