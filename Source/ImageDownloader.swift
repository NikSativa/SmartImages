import Combine
import Foundation
import Threading

#if os(iOS) || os(tvOS) || os(watchOS) || supportsVisionOS
import UIKit
#elseif os(macOS)
import Cocoa
#else
#error("unsupported os")
#endif

public enum ImageDownloaderError: Error {
    case decodingFailed
}

/// A powerful and flexible image downloader that provides intelligent image loading with prioritization, caching, and processing capabilities.
///
/// `ImageDownloader` is the main class for downloading and managing image resources in SmartImages. It coordinates
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
/// let downloader = ImageDownloader(
///     network: ImageDownloaderNetworkAdaptor(),
///     cache: ImageCacheInfo(folderName: "MyImages"),
///     concurrentLimit: 6
/// )
///
/// downloader.download(of: ImageInfo(url: imageURL), completion: { image in
///     // Handle loaded image
/// })
/// ```
///
/// ## Customization
/// - Provide custom networking implementations via `ImageDownloaderNetwork`
/// - Configure caching behavior with `ImageCacheInfo`
/// - Add custom image processors for transformations
/// - Set download priorities and concurrency limits
public final class ImageDownloader {
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
    private var cacheInfos: [URL: ImageInfo] = [:]
    private var cacheActiveTasks: [URL: ImageDownloaderTask] = [:]

    /// The network implementation used for downloading images.
    private let network: ImageDownloaderNetwork
    /// The processor for decoding images.
    private let imageDecoding: ImageDecodingProcessor
    /// The queue for managing image download tasks.
    private let downloadQueue: ImageDownloadQueueing
    /// The cache implementation for storing downloaded images.
    public let imageCache: ImageCaching?

    /// Creates a new `ImageDownloader` instance with the specified configuration.
    ///
    /// - Parameters:
    ///   - network: The network implementation for downloading images. Required for all download operations.
    ///   - cache: Optional cache configuration for storing downloaded images. If `nil`, no caching will be performed.
    ///   - decoders: Array of image decoders to use for processing downloaded data. Defaults to `[ImageDecoders.Default()]`.
    ///     The first decoder that successfully processes the data will be used.
    ///   - decodingQueue: Queue for image decoding operations. If `.absent`, decoding happens synchronously with networking.
    ///   - limit: Maximum number of concurrent downloads. If `nil`, downloads are unlimited (use with caution).
    public required init(network: ImageDownloaderNetwork,
                         cache: ImageCacheInfo? = nil,
                         decoders: [ImageDecoding] = [],
                         decodingQueue: DelayedQueue = .absent,
                         concurrentLimit limit: Int? = nil) {
        self.network = network
        self.imageCache = cache.map(ImageCache.init(info:))
        self.imageDecoding = ImageDecodingProcessor(decoders: decoders)
        self.downloadQueue = ImageDownloadQueue(concurrentImagesLimit: limit)
        self.decodingQueue = decodingQueue
    }

    /// The internal initializer is for testing purposes only.
    internal init(network: ImageDownloaderNetwork,
                  decodingQueue: DelayedQueue,
                  imageCache: ImageCaching? = nil,
                  imageDecoding: ImageDecodingProcessor,
                  downloadQueue: ImageDownloadQueueing) {
        self.network = network
        self.imageCache = imageCache
        self.imageDecoding = imageDecoding
        self.downloadQueue = downloadQueue
        self.decodingQueue = decodingQueue
    }

    private func add(_ holder: USendable<ImageDownloading.ImageReference>, for url: URL, completion: @escaping ImageClosure) {
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

    private func addInfoIfNeeded(_ info: ImageInfo) {
        mutex.sync {
            if let cached = cacheInfos[info.url] {
                if cached.priority < info.priority {
                    cacheInfos[info.url] = info
                }
            } else {
                cacheInfos[info.url] = info
            }
        }
    }

    private func checkCachedImage(for info: ImageInfo,
                                  animated animation: ImageAnimation?) -> Bool {
        if let data = imageCache?.cached(for: info.url) {
            decodingQueue.fire { [self] in
                handleLoaded(.success(data), animated: animation, for: info.url)
            }
            return true
        }
        return false
    }

    private func scheduleDownload(of info: ImageInfo,
                                  animated animation: ImageAnimation?) {
        if checkCachedImage(for: info, animated: animation) {
            return
        }

        let url = info.url
        let prioritizer: ImageDownloadQueueing.Prioritizer = { [weak self] in
            guard let self else {
                return .preset(info.priority)
            }

            return mutex.sync {
                if let cached = self.cacheViews[url] {
                    cached.filterNils()
                    if !cached.isEmpty {
                        return .hasImageView
                    }
                }

                if let cached = self.cacheInfos[url] {
                    return .preset(cached.priority)
                }

                return .preset(info.priority)
            }
        }

        downloadQueue.add(hash: url, prioritizer: prioritizer) { [unowned self] completion in
            let info = mutex.sync {
                return cacheInfos[url]
            }

            let task = network.request(with: info?.url ?? url,
                                       cachePolicy: info?.cachePolicy,
                                       timeoutInterval: info?.timeoutInterval,
                                       completion: { [self] result in
                                           mutex.sync {
                                               cacheActiveTasks[url] = nil
                                           }

                                           completion()
                                           decodingQueue.fire { [self] in
                                               handleLoaded(result, animated: animation, for: url)
                                           }
                                       })

            mutex.sync {
                cacheActiveTasks[url] = task
            }
            task.start()
        }
    }

    private func handleLoaded(_ result: Result<Data, Error>,
                              animated animation: ImageAnimation?,
                              for url: URL) {
        let (info, views, closures) = mutex.sync {
            defer {
                cacheInfos[url] = nil
                cacheViews[url] = nil
                cacheClosures[url] = nil
            }

            let views = (cacheViews[url]?.cached ?? []).map {
                return WeakViews.InstanceStub(completion: $0.completion,
                                              holder: $0.view())
            }
            let closures = (cacheClosures[url] ?? []).map(\.closure)
            return (cacheInfos[url], views, closures)
        }

        let completion: ImageClosure = { [self, url] result in
            result.sourceURL = url
            handle(result,
                   animated: animation,
                   views: views,
                   closures: closures)
        }

        switch result {
        case .success(let success):
            let image = imageDecoding.decode(success)
            if let image {
                imageCache?.store(success, for: url)

                let processor = ImageProcessors.Composition(processors: info?.processors ?? [])
                let processedImage = processor.process(image)
                completion(.success(processedImage))
            } else {
                imageCache?.remove(for: url)
                completion(.failure(ImageDownloaderError.decodingFailed))
            }

        case .failure(let error):
            imageCache?.remove(for: url)
            completion(.failure(error))
        }
    }

    private func handle(_ image: Result<Image, Error>,
                        animated animation: ImageAnimation?,
                        views: [WeakViews.InstanceStub],
                        closures: [ImageClosure]) {
        let sendableImage = USendable(value: image)
        let sendableClosures = USendable(value: closures)
        Queue.isolatedMain.sync {
            let result = sendableImage.value
            let closures = sendableClosures.value

            for cached in views {
                if let view = cached.holder as? ImageView {
                    animation.animate(view, image: result.image)
                }
                cached.completion(result)
            }

            for cl in closures {
                cl(result)
            }
        }
    }

    private func needDownload(of info: ImageInfo, for holder: USendable<ImageDownloading.ImageReference>) -> Bool {
        return Queue.isolatedMain.sync {
            if let imageView = holder.value as? ImageView,
               let cachePolicy = info.cachePolicy,
               cachePolicy.canUseCachedData,
               let image = imageView.image,
               let currentSourceURL = image.sourceURL,
               currentSourceURL == info.url {
                return false
            }
            return true
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
                        self.cacheInfos[url] = nil
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

// MARK: - ImageDownloading

extension ImageDownloader: ImageDownloading {
    public func download(of info: ImageInfo,
                         for reference: ImageDownloading.ImageReference,
                         animated animation: ImageAnimation?,
                         placeholder: ImagePlaceholder,
                         completion: @escaping ImageClosure) {
        let unsafeReference: USendable = .init(reference)

        guard needDownload(of: info, for: unsafeReference) else {
            return
        }

        if let imageView = reference as? ImageView {
            Queue.isolatedMain.sync {
                imageView.setPlaceholder(placeholder)
            }
        }

        add(unsafeReference, for: info.url, completion: completion)
        addInfoIfNeeded(info)
        scheduleDownload(of: info, animated: animation)
    }

    public func download(of info: ImageInfo, completion: @escaping ImageClosure) -> AnyCancellable {
        let url = info.url
        let uniq = add(url, with: completion)

        addInfoIfNeeded(info)
        scheduleDownload(of: info, animated: nil)

        return cancel(url, token: uniq)
    }

    public func prefetching(of info: ImageInfo, completion: @escaping ImageClosure) -> AnyCancellable {
        let url = info.url
        let uniq = add(url, with: completion)

        addInfoIfNeeded(info)
        scheduleDownload(of: info, animated: nil)

        return cancel(url, token: uniq)
    }

    public func prefetch(of info: ImageInfo,
                         completion: @escaping ImageClosure) {
        _ = add(info.url, with: completion)
        addInfoIfNeeded(info)
        scheduleDownload(of: info, animated: nil)
    }

    public func cancel(for reference: ImageDownloading.ImageReference) {
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

private extension ImageAnimation? {
    #if swift(>=6.0)
    @MainActor
    #endif
    func animate(_ imageView: ImageView, image: Image?) {
        // ignore nil, to leave placeholder
        guard let image else {
            return
        }

        switch self {
        #if os(iOS) || os(tvOS)
        case .crossDissolve:
            if image.size == imageView.image?.size,
               let currentSourceURL = imageView.image?.sourceURL,
               image.sourceURL == currentSourceURL {
                return // No need to animate the same image, it’s already here
            }

            UIView.transition(with: imageView,
                              duration: 0.24,
                              options: [.transitionCrossDissolve, .beginFromCurrentState],
                              animations: {
                                  imageView.image = image
                              })
        #elseif os(macOS) || os(watchOS) || supportsVisionOS
        // not supported yet
        #else
            #error("unsupported os")
        #endif

        case .custom(let animation):
            animation(imageView, image)

        case .none:
            imageView.image = image
        }
    }
}

private final class WeakViews {
    struct Stub {
        let completion: ImageClosure
        let view: () -> ImageDownloading.ImageReference?
    }

    /// used to instantiate and retain ImageView from Stub and then to run on main queue
    struct InstanceStub {
        let completion: ImageClosure
        let holder: ImageDownloading.ImageReference?
    }

    private(set) var cached: [Stub] = []

    var isEmpty: Bool {
        return cached.isEmpty
    }

    func add(_ imageView: ImageDownloading.ImageReference, completion: @escaping ImageClosure) {
        let stub: Stub = .init(completion: completion) { [weak imageView] in
            return imageView
        }
        cached.append(stub)
    }

    func remove(_ imageView: ImageDownloading.ImageReference) {
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

private extension ImageView {
    var unsendableImage: USendable<Image?> {
        return .init(value: image)
    }
}

private extension Result<Image, Error> {
    var image: Image? {
        switch self {
        case .success(let image):
            return image
        case .failure:
            return nil
        }
    }
}

private extension Result<Image, Error> {
    var sourceURL: URL? {
        get {
            return image?.sourceURL
        }
        nonmutating set {
            image?.sourceURL = newValue
        }
    }
}

#if swift(>=6.0)
extension ImageDownloader: @unchecked Sendable {}

extension WeakViews: @unchecked Sendable {}
extension WeakViews.Stub: @unchecked Sendable {}
extension WeakViews.InstanceStub: @unchecked Sendable {}
#endif
