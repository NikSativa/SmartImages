import Combine
import Foundation
import Threading

/// An `ImageFetching` implementation suitable for SwiftUI previews and unit tests.
///
/// Returns a deterministic result without performing real network I/O.
/// Configure either a single image, a per-URL map of images, or a forced error.
/// An optional artificial delay can simulate network latency.
///
/// ## Usage
/// ```swift
/// // Always succeeds with the same image.
/// SmartImageView(url: url, imageFetcher: PreviewImageFetcher(image: previewImage)) { ... }
///
/// // Per-URL responses.
/// let fetcher = PreviewImageFetcher(images: [
///     url1: image1,
///     url2: image2
/// ])
///
/// // Always fails.
/// let fetcher = PreviewImageFetcher(error: URLError(.notConnectedToInternet))
/// ```
public final class PreviewImageFetcher: ImageFetching, @unchecked Sendable {
    public enum Response {
        case image(SmartImage)
        case images([URL: SmartImage])
        case failure(Error)
    }

    public let imageCache: ImageCaching? = nil

    private let response: Response
    private let delay: TimeInterval

    public init(response: Response, delay: TimeInterval = 0) {
        self.response = response
        self.delay = delay
    }

    public convenience init(image: SmartImage, delay: TimeInterval = 0) {
        self.init(response: .image(image), delay: delay)
    }

    public convenience init(images: [URL: SmartImage], delay: TimeInterval = 0) {
        self.init(response: .images(images), delay: delay)
    }

    public convenience init(error: Error, delay: TimeInterval = 0) {
        self.init(response: .failure(error), delay: delay)
    }

    public func download(of request: ImageRequest,
                         for reference: ImageReference,
                         completion: @escaping ImageClosure) {
        deliver(for: request.url, completion: completion)
    }

    public func download(of request: ImageRequest, completion: @escaping ImageClosure) -> AnyCancellable {
        deliver(for: request.url, completion: completion)
        return AnyCancellable {}
    }

    public func prefetch(of request: ImageRequest, completion: @escaping ImageClosure) {
        deliver(for: request.url, completion: completion)
    }

    public func prefetching(of request: ImageRequest, completion: @escaping ImageClosure) -> AnyCancellable {
        deliver(for: request.url, completion: completion)
        return AnyCancellable {}
    }

    public func cancel(for reference: ImageReference) {
        // no-op
    }

    private func deliver(for url: URL, completion: @escaping ImageClosure) {
        let result = makeResult(for: url)
        let unsafeResult = USendable(value: result)
        let block: VoidClosure = {
            Queue.isolatedMain.sync {
                completion(unsafeResult.value)
            }
        }

        if delay > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                block()
            }
        } else {
            block()
        }
    }

    private func makeResult(for url: URL) -> Result<SmartImage, Error> {
        switch response {
        case let .image(image):
            return .success(image)
        case let .images(map):
            if let image = map[url] {
                return .success(image)
            }
            return .failure(PreviewImageFetcherError.notFound(url))
        case let .failure(error):
            return .failure(error)
        }
    }
}

/// Errors emitted by `PreviewImageFetcher`.
public enum PreviewImageFetcherError: Error {
    case notFound(URL)
}
