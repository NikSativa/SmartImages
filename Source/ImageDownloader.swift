import Combine
import Foundation
import NQueue

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(macOS)
import Cocoa
#else
#error("unsupported os")
#endif

public final class ImageDownloader {
    private final class ClosureToken {
        let closure: ImageClosure

        init(closure: @escaping ImageClosure) {
            self.closure = closure
        }
    }

    private let mutex: Mutexing = Mutex.pthread(.recursive)
    private let decodingQueue: Queueable = Queue.custom(label: "ImageDownloader.decodingQueue",
                                                        qos: .utility,
                                                        attributes: .concurrent)
    private let mainQueue: Queueable = Queue.custom(label: "ImageDownloader.mainQueue",
                                                    qos: .utility,
                                                    attributes: .serial)

    private var cacheViews: [URL: WeakViews] = [:]
    private var cacheClosures: [URL: [ClosureToken]] = [:]
    private var cacheInfos: [URL: ImageInfo] = [:]
    private var cacheActiveTasks: [URL: any Cancellable] = [:]

    private let network: ImageDownloaderNetwork
    private let imageCache: ImageCaching?
    private let imageDecoding: ImageDecodingProcessor
    private let downloadQueue: ImageDownloadQueueing

    internal init(network: ImageDownloaderNetwork,
                  imageCache: ImageCaching? = nil,
                  imageDecoding: ImageDecodingProcessor,
                  downloadQueue: ImageDownloadQueueing) {
        self.network = network
        self.imageCache = imageCache
        self.imageDecoding = imageDecoding
        self.downloadQueue = downloadQueue
    }

    public static func create(network: ImageDownloaderNetwork,
                              cache: ImageCacheInfo? = nil,
                              decoders: [ImageDecoding] = [ImageDecoders.Default()],
                              concurrentImagesLimit limit: Int? = nil) -> ImageDownloader {
        let imageCache: ImageCache? = cache.map(ImageCache.init(info:))
        return .init(network: network,
                     imageCache: imageCache,
                     imageDecoding: ImageDecodingProcessor(decoders: decoders),
                     downloadQueue: ImageDownloadQueue(concurrentImagesLimit: limit))
    }

    private func add(_ imageView: ImageView, for url: URL, completion: @escaping ImageClosure) {
        mutex.sync {
            cacheViews = cacheViews.filter { _, views in
                views.remove(imageView)
                views.filterNils()
                return !views.isEmpty
            }

            if let container = cacheViews[url] {
                container.add(imageView, completion: completion)
            } else {
                let container: WeakViews = .init()
                container.add(imageView, completion: completion)
                cacheViews[url] = container
            }
        }
    }

    private func add(_ url: URL, with completion: @escaping ImageClosure) -> ClosureToken {
        return mutex.sync {
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
            decodingQueue.async { [self] in
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
        let prioritizer: () -> ImageDownloadQueuePriority = { [weak self] in
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
                                       cachePolicy: info?.cachePolicy ?? .useProtocolCachePolicy,
                                       timeoutInterval: info?.timeoutInterval ?? 60) { [self] result in
                mutex.sync {
                    cacheActiveTasks[url] = nil
                }

                completion()
                decodingQueue.async { [self] in
                    handleLoaded(result, animated: animation, for: url)
                }
            }

            mutex.sync {
                cacheActiveTasks[url] = task
            }
            task.start()
        }
    }

    private func handleLoaded(_ result: Result<Data, Error>,
                              animated animation: ImageAnimation?,
                              for url: URL) {
        assert(!Thread.isMainThread)

        let (info, views, closures) = mutex.sync {
            defer {
                cacheInfos[url] = nil
                cacheViews[url] = nil
                cacheClosures[url] = nil
            }

            let views = (cacheViews[url]?.cached ?? []).map {
                return WeakViews.InstanceStub(completion: $0.completion,
                                              view: $0.view())
            }
            let closures = (cacheClosures[url] ?? []).map(\.closure)
            return (cacheInfos[url], views, closures)
        }

        let completion: ImageClosure = { [self, url] image in
            image?.sourceURL = url
            handle(image,
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
                completion(processedImage)
            } else {
                imageCache?.remove(for: url)
                completion(nil)
            }
        case .failure:
            imageCache?.remove(for: url)
            completion(nil)
        }
    }

    private func handle(_ image: Image?,
                        animated animation: ImageAnimation?,
                        views: [WeakViews.InstanceStub],
                        closures: [ImageClosure]) {
        Queue.main.async {
            for cached in views {
                if let view = cached.view {
                    animation.animate(view, image: image)
                }
                cached.completion(image)
            }

            for cl in closures {
                cl(image)
            }
        }
    }

    private func needDownload(of info: ImageInfo, for imageView: ImageView) -> Bool {
        if info.cachePolicy.canUseCachedData,
           let image = imageView.image,
           let currentSourceURL = image.sourceURL,
           currentSourceURL == info.url {
            return false
        }
        return true
    }
}

// MARK: - ImageDownloading

extension ImageDownloader: ImageDownloading {
    public func download(of info: ImageInfo,
                         for imageView: ImageView,
                         animated animation: ImageAnimation?,
                         completion: @escaping ImageClosure) {
        guard needDownload(of: info, for: imageView) else {
            return
        }

        add(imageView, for: info.url, completion: completion)
        addInfoIfNeeded(info)
        scheduleDownload(of: info, animated: animation)
    }

    public func download(of info: ImageInfo,
                         completion: @escaping ImageClosure) -> AnyCancellable {
        let url = info.url
        let uniq = add(url, with: completion)

        addInfoIfNeeded(info)
        scheduleDownload(of: info, animated: nil)

        return .init { [weak self, uniq, url] in
            guard let self else {
                return
            }

            mutex.sync { [weak self] in
                guard let self else {
                    return
                }

                var arr = cacheClosures[url] ?? []
                arr = arr.filter {
                    return uniq !== $0
                }

                if arr.isEmpty {
                    cacheClosures[url] = nil

                    if cacheViews[url] == nil {
                        cacheInfos[url] = nil
                        cacheActiveTasks[url]?.cancel()
                        cacheActiveTasks[url] = nil
                    }
                } else {
                    cacheClosures[url] = arr
                }
            }
        }
    }

    public func predownload(of info: ImageInfo,
                            completion: @escaping ImageClosure) {
        _ = add(info.url, with: completion)
        addInfoIfNeeded(info)
        scheduleDownload(of: info, animated: nil)
    }

    public func cancel(for imageView: ImageView) {
        mutex.sync {
            cacheViews = cacheViews.filter { _, views in
                views.remove(imageView)
                views.filterNils()
                return !views.isEmpty
            }
        }
    }
}

private extension ImageAnimation? {
    func animate(_ imageView: ImageView, image: Image?) {
        // ignore nil, to leave placeholder
        guard let image else {
            return
        }

        assert(Thread.isMainThread)
        switch self {
        #if os(iOS) || os(tvOS) || os(watchOS)
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
        #elseif os(macOS)
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
        let view: () -> ImageView?
    }

    /// used to instantiate and retain ImageView from Stub and then to run on main queue
    struct InstanceStub {
        let completion: ImageClosure
        let view: ImageView?
    }

    private(set) var cached: [Stub] = []

    var isEmpty: Bool {
        return cached.isEmpty
    }

    func add(_ imageView: ImageView, completion: @escaping ImageClosure) {
        let stub: Stub = .init(completion: completion) { [weak imageView] in
            return imageView
        }
        cached.append(stub)
    }

    func remove(_ imageView: ImageView) {
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
