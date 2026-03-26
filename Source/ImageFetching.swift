import Combine
import Foundation
import Threading

#if swift(>=6.0)
/// A protocol representing the behavior of downloading images asynchronously.
public protocol ImageFetching: Sendable {
    /// any object when referencing the downloading task
    /// at UIKit can be UIImageView
    /// at SwiftUI can be ImageReference `@State var reference: ImageReference = .init()`
    typealias ImageReference = AnyObject

    /// The image cache used for downloaded images.
    var imageCache: ImageCaching? { get }

    /// Downloads an image with the specified info and registers the reference for prioritization.
    /// The reference is stored as weak — if it is still alive, the download receives the highest priority.
    func download(of request: ImageRequest,
                  for reference: ImageReference,
                  completion: @escaping ImageClosure)

    /// Downloads an image with the specified info.
    func download(of request: ImageRequest, completion: @escaping ImageClosure) -> AnyCancellable

    /// Prefetches an image with the specified info.
    func prefetch(of request: ImageRequest, completion: @escaping ImageClosure)

    /// Prefetches an image with the specified info.
    func prefetching(of request: ImageRequest, completion: @escaping ImageClosure) -> AnyCancellable

    /// Cancels the download for the specified reference.
    func cancel(for reference: ImageReference)
}
#else
/// A protocol representing the behavior of downloading images asynchronously.
public protocol ImageFetching {
    /// any object when referencing the downloading task
    /// at UIKit can be UIImageView
    /// at SwiftUI can be ImageReference `@State var reference: ImageReference = .init()`
    typealias ImageReference = AnyObject

    /// The image cache used for downloaded images.
    var imageCache: ImageCaching? { get }

    /// Downloads an image with the specified info and registers the reference for prioritization.
    /// The reference is stored as weak — if it is still alive, the download receives the highest priority.
    func download(of request: ImageRequest,
                  for reference: ImageReference,
                  completion: @escaping ImageClosure)

    /// Downloads an image with the specified info.
    func download(of request: ImageRequest, completion: @escaping ImageClosure) -> AnyCancellable

    /// Prefetches an image with the specified info.
    func prefetch(of request: ImageRequest, completion: @escaping ImageClosure)

    /// Prefetches an image with the specified info.
    func prefetching(of request: ImageRequest, completion: @escaping ImageClosure) -> AnyCancellable

    /// Cancels the download for the specified reference.
    func cancel(for reference: ImageReference)
}
#endif

// MARK: - Async/Await

public extension ImageFetching {
    /// Downloads an image with the specified request.
    func download(of request: ImageRequest) async throws -> SmartImage {
        try await withCheckedThrowingContinuation { continuation in
            _ = download(of: request) { result in
                continuation.resume(with: USendable(value: result).value)
            }
        }
    }

    /// Downloads an image from the given URL.
    func download(url: URL,
                  cachePolicy: URLRequest.CachePolicy? = nil,
                  timeoutInterval: TimeInterval? = nil,
                  processors: [ImageProcessor] = [],
                  priority: FetchPriority = .default) async throws -> SmartImage {
        let request = ImageRequest(url: url,
                                   cachePolicy: cachePolicy,
                                   timeoutInterval: timeoutInterval,
                                   processors: processors,
                                   priority: priority)
        return try await download(of: request)
    }

    /// Downloads an image with the specified request for a reference.
    func download(of request: ImageRequest, for reference: ImageReference) async throws -> SmartImage {
        try await withCheckedThrowingContinuation { continuation in
            download(of: request, for: reference) { result in
                continuation.resume(with: USendable(value: result).value)
            }
        }
    }

    /// Prefetches an image with the specified request.
    func prefetching(of request: ImageRequest) async throws -> SmartImage {
        try await withCheckedThrowingContinuation { continuation in
            _ = prefetching(of: request) { result in
                continuation.resume(with: USendable(value: result).value)
            }
        }
    }
}

// MARK: - Convenience

public extension ImageFetching {
    /// Downloads an image with the specified request.
    func download(of request: ImageRequest) -> AnyCancellable {
        return download(of: request, completion: { _ in })
    }

    /// Downloads an image with URL.
    func download(url: URL,
                  cachePolicy: URLRequest.CachePolicy? = nil,
                  timeoutInterval: TimeInterval? = nil,
                  processors: [ImageProcessor] = [],
                  priority: FetchPriority = .default,
                  completion: ImageClosure? = nil) -> AnyCancellable {
        let request = ImageRequest(url: url,
                                   cachePolicy: cachePolicy,
                                   timeoutInterval: timeoutInterval,
                                   processors: processors,
                                   priority: priority)
        return download(of: request,
                        completion: completion ?? { _ in })
    }

    /// Prefetches an image with the specified request.
    func prefetch(of request: ImageRequest) {
        prefetch(of: request, completion: { _ in })
    }

    /// Prefetches an image with the URL.
    func prefetch(url: URL,
                  cachePolicy: URLRequest.CachePolicy? = nil,
                  timeoutInterval: TimeInterval? = nil,
                  processors: [ImageProcessor] = [],
                  priority: FetchPriority = .prefetch,
                  completion: @escaping ImageClosure = { _ in }) {
        let request = ImageRequest(url: url,
                                   cachePolicy: cachePolicy,
                                   timeoutInterval: timeoutInterval,
                                   processors: processors,
                                   priority: priority)
        prefetch(of: request, completion: completion)
    }

    /// Prefetches an image with the URL.
    func prefetching(url: URL,
                     cachePolicy: URLRequest.CachePolicy? = nil,
                     timeoutInterval: TimeInterval? = nil,
                     processors: [ImageProcessor] = [],
                     priority: FetchPriority = .prefetch,
                     completion: @escaping ImageClosure = { _ in }) -> AnyCancellable {
        let request = ImageRequest(url: url,
                                   cachePolicy: cachePolicy,
                                   timeoutInterval: timeoutInterval,
                                   processors: processors,
                                   priority: priority)
        return prefetching(of: request, completion: completion)
    }
}
