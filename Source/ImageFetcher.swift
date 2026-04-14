import Combine
import Foundation
import Threading

/// Errors that can occur during image downloading.
public enum ImageFetchingError: Error {
    case decodingFailed
}

/// A powerful and flexible image downloader that provides intelligent image loading with prioritization, caching, and processing capabilities.
///
/// `ImageFetcher` is the main class for downloading and managing image resources in SmartImages. It coordinates
/// networking, caching, decoding, and queuing operations to provide efficient image loading with minimal setup.
///
/// ## Key Features
/// - **Intelligent Prioritization**: Images with visible image views are prioritized over background downloads
/// - **Efficient Caching**: Built-in memory and disk caching with configurable limits
/// - **Concurrent Downloads**: Configurable concurrent download limits for optimal performance
/// - **Image Processing**: Support for custom image processors (resizing, cropping, etc.)
/// - **Thread-Safe**: All operations are thread-safe and can be used from any queue
///
/// ## Basic Usage
/// ```swift
/// let downloader = ImageFetcher(
///     network: YourNetworkImpl(),
///     cache: ImageCacheConfiguration(folderName: "MyImages"),
///     concurrentLimit: 6
/// )
///
/// downloader.download(of: ImageRequest(url: imageURL), completion: { image in
///     // Handle loaded image
/// })
/// ```
///
/// ## Customization
/// - Provide custom networking implementations via `ImageNetworkProvider`
/// - Configure caching behavior with `ImageCacheConfiguration`
/// - Add custom image processors for transformations
/// - Set download priorities and concurrency limits
public final class ImageFetcher {
    private final class ClosureToken {
        let closure: ImageClosure

        init(closure: @escaping ImageClosure) {
            self.closure = closure
        }
    }

    private let mutex: Locking = AnyLock.pthread(.recursive)
    private let decodingQueue: DelayedQueue
    private var cacheViews: [URL: WeakViews] = [:]
    private var cacheClosures: [URL: [ClosureToken]] = [:]
    private var cacheRequests: [URL: ImageRequest] = [:]
    private var cacheActiveTasks: [URL: ImageNetworkTask] = [:]

    /// The network implementation used for downloading images.
    private let network: ImageNetworkProvider
    /// The processor for decoding images.
    private let imageDecoding: ImageDecodingProcessor
    /// The queue for managing image download tasks.
    private let downloadQueue: ImageQueueScheduling
    /// The cache implementation for storing downloaded images.
    public let imageCache: ImageCaching?

    /// Creates a new `ImageFetcher` instance with the specified configuration.
    ///
    /// - Parameters:
    ///   - network: The network implementation for downloading images. Required for all download operations.
    ///   - cache: Optional cache configuration for storing downloaded images. If `nil`, no caching will be performed.
    ///   - decoders: Array of image decoders to use for processing downloaded data. Defaults to `[ImageDecoders.Default()]`.
    ///     The first decoder that successfully processes the data will be used.
    ///   - decodingQueue: Queue for image decoding operations. If `.absent`, decoding happens synchronously with networking.
    ///   - limit: Maximum number of concurrent downloads. If `nil`, downloads are unlimited (use with caution).
    public required init(network: ImageNetworkProvider,
                         cache: ImageCacheConfiguration? = nil,
                         decoders: [ImageDecoding] = [],
                         decodingQueue: DelayedQueue = .absent,
                         concurrentLimit limit: Int? = nil) {
        self.network = network
        self.imageCache = cache.map(ImageCache.init(configuration:))
        self.imageDecoding = ImageDecodingProcessor(decoders: decoders)
        self.downloadQueue = ImageDownloadQueue(concurrentImagesLimit: limit)
        self.decodingQueue = decodingQueue
    }

    /// The internal initializer is for testing purposes only.
    internal init(network: ImageNetworkProvider,
                  decodingQueue: DelayedQueue,
                  imageCache: ImageCaching? = nil,
                  imageDecoding: ImageDecodingProcessor,
                  downloadQueue: ImageQueueScheduling) {
        self.network = network
        self.imageCache = imageCache
        self.imageDecoding = imageDecoding
        self.downloadQueue = downloadQueue
        self.decodingQueue = decodingQueue
    }

    private func add(_ holder: USendable<ImageFetching.ImageReference>, for url: URL, completion: @escaping ImageClosure) {
        mutex.sync {
            cacheViews = cacheViews.filter { _, views in
                views.remove(holder.value)
                views.filterNils()
                return !views.isEmpty
            }

            if let container = cacheViews[url] {
                container.add(holder.value, completion: completion)
            } else {
                let container: WeakViews = .init()
                container.add(holder.value, completion: completion)
                cacheViews[url] = container
            }
        }
    }

    private func add(_ url: URL, with completion: @escaping ImageClosure) -> ClosureToken {
        return mutex.syncUnchecked {
            let uniq = ClosureToken(closure: completion)
            var arr = cacheClosures[url] ?? []
            arr.append(uniq)
            cacheClosures[url] = arr
            return uniq
        }
    }

    private func addRequestIfNeeded(_ request: ImageRequest) {
        mutex.sync {
            if let cached = cacheRequests[request.url] {
                if cached.priority < request.priority {
                    cacheRequests[request.url] = request
                }
            } else {
                cacheRequests[request.url] = request
            }
        }
    }

    private func checkCachedImage(for request: ImageRequest) -> Bool {
        if let data = imageCache?.cached(for: request.url) {
            decodingQueue.fire { [self] in
                handleLoaded(.success(data), for: request.url)
            }
            return true
        }
        return false
    }

    private func scheduleDownload(of request: ImageRequest) {
        if checkCachedImage(for: request) {
            return
        }

        let url = request.url
        let prioritizer: ImageQueueScheduling.Prioritizer = { [weak self] in
            guard let self else {
                return .preset(request.priority)
            }

            return mutex.sync {
                if let cached = self.cacheViews[url] {
                    cached.filterNils()
                    if !cached.isEmpty {
                        return .hasImageView
                    }
                }

                if let cached = self.cacheRequests[url] {
                    return .preset(cached.priority)
                }

                return .preset(request.priority)
            }
        }

        downloadQueue.add(hash: url, prioritizer: prioritizer) { [weak self] completion in
            guard let self else {
                completion()
                return
            }

            let cachedRequest = mutex.sync {
                return self.cacheRequests[url]
            }

            // swiftformat:disable redundantSelf
            let task = network.request(with: cachedRequest?.url ?? url,
                                       cachePolicy: cachedRequest?.cachePolicy,
                                       timeoutInterval: cachedRequest?.timeoutInterval,
                                       headers: cachedRequest?.headers,
                                       completion: { [self] result in
                                           self.mutex.sync {
                                               self.cacheActiveTasks[url] = nil
                                           }

                                           completion()
                                           self.decodingQueue.fire { [self] in
                                               self.handleLoaded(result, for: url)
                                           }
                                       })
            // swiftformat:enable redundantSelf

            mutex.sync {
                self.cacheActiveTasks[url] = task
            }
            task.start()
        }
    }

    private func handleLoaded(_ result: Result<Data, Error>,
                              for url: URL) {
        let (cachedRequest, views, closures) = mutex.sync {
            defer {
                cacheRequests[url] = nil
                cacheViews[url] = nil
                cacheClosures[url] = nil
            }

            let views = (cacheViews[url]?.cached ?? []).map {
                return WeakViews.InstanceStub(completion: $0.completion,
                                              holder: $0.view())
            }
            let closures = (cacheClosures[url] ?? []).map(\.closure)
            return (cacheRequests[url], views, closures)
        }

        let completion: ImageClosure = { [self] result in
            handle(result,
                   views: views,
                   closures: closures)
        }

        switch result {
        case let .success(success):
            let image = imageDecoding.decode(success)
            if let image {
                imageCache?.store(success, for: url)

                let processor = ImageProcessors.Composition(processors: cachedRequest?.processors ?? [])
                let processedImage = processor.process(image)

                Queue.isolatedMain.sync {
                    completion(.success(processedImage))
                }
            } else {
                imageCache?.remove(for: url)
                Queue.isolatedMain.sync {
                    completion(.failure(ImageFetchingError.decodingFailed))
                }
            }

        case let .failure(error):
            imageCache?.remove(for: url)

            Queue.isolatedMain.sync {
                completion(.failure(error))
            }
        }
    }

    private func handle(_ image: Result<SmartImage, Error>,
                        views: [WeakViews.InstanceStub],
                        closures: [ImageClosure]) {
        let sendableImage = USendable(value: image)
        let sendableClosures = USendable(value: closures)
        Queue.isolatedMain.sync {
            let result = sendableImage.value
            let closures = sendableClosures.value

            for cached in views {
                cached.completion(result)
            }

            for cl in closures {
                cl(result)
            }
        }
    }

    private func cancel(_ url: URL, token uniq: ClosureToken) -> AnyCancellable {
        return .init { [weak self, uniq, url] in
            guard let self else {
                return
            }

            mutex.syncUnchecked { [uniq, url] in
                var arr = self.cacheClosures[url] ?? []
                arr = arr.filter {
                    return uniq !== $0
                }

                if arr.isEmpty {
                    self.cacheClosures[url] = nil

                    if self.cacheViews[url] == nil {
                        self.cacheRequests[url] = nil
                        self.cacheActiveTasks[url]?.cancel()
                        self.cacheActiveTasks[url] = nil
                    }
                } else {
                    self.cacheClosures[url] = arr
                }
            }
        }
    }
}

// MARK: - ImageFetching

extension ImageFetcher: ImageFetching {
    public func download(of request: ImageRequest,
                         for reference: ImageFetching.ImageReference,
                         completion: @escaping ImageClosure) {
        let unsafeReference: USendable = .init(reference)
        add(unsafeReference, for: request.url, completion: completion)
        addRequestIfNeeded(request)
        scheduleDownload(of: request)
    }

    public func download(of request: ImageRequest, completion: @escaping ImageClosure) -> AnyCancellable {
        let url = request.url
        let uniq = add(url, with: completion)

        addRequestIfNeeded(request)
        scheduleDownload(of: request)

        return cancel(url, token: uniq)
    }

    public func prefetching(of request: ImageRequest, completion: @escaping ImageClosure) -> AnyCancellable {
        let url = request.url
        let uniq = add(url, with: completion)

        addRequestIfNeeded(request)
        scheduleDownload(of: request)

        return cancel(url, token: uniq)
    }

    public func prefetch(of request: ImageRequest,
                         completion: @escaping ImageClosure) {
        _ = add(request.url, with: completion)
        addRequestIfNeeded(request)
        scheduleDownload(of: request)
    }

    public func cancel(for reference: ImageFetching.ImageReference) {
        let unsafeImageView: USendable = .init(reference)
        mutex.sync {
            cacheViews = cacheViews.filter { _, views in
                views.remove(unsafeImageView.value)
                views.filterNils()
                return !views.isEmpty
            }
        }
    }
}

// MARK: - WeakViews

private final class WeakViews {
    struct Stub {
        let completion: ImageClosure
        let view: () -> ImageFetching.ImageReference?
    }

    /// Used to instantiate and retain the view reference from Stub and then to run on main queue.
    struct InstanceStub {
        let completion: ImageClosure
        let holder: ImageFetching.ImageReference?
    }

    private(set) var cached: [Stub] = []

    var isEmpty: Bool {
        return cached.isEmpty
    }

    func add(_ imageView: ImageFetching.ImageReference, completion: @escaping ImageClosure) {
        let stub: Stub = .init(completion: completion) { [weak imageView] in
            return imageView
        }
        cached.append(stub)
    }

    func remove(_ imageView: ImageFetching.ImageReference) {
        cached = cached.filter {
            if let cached = $0.view() {
                return cached !== imageView
            }
            return false
        }
    }

    func filterNils() {
        cached = cached.filter { stub in
            return stub.view() != nil
        }
    }
}

// MARK: - Sendable

#if swift(>=6.0)
extension ImageFetcher: @unchecked Sendable {}

extension WeakViews: @unchecked Sendable {}
extension WeakViews.Stub: @unchecked Sendable {}
extension WeakViews.InstanceStub: @unchecked Sendable {}
#endif
