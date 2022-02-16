import Foundation
import NCallback
import NQueue
import NRequest
import UIKit

public protocol ImageDownloader {
    // MARK: - Downloading

    func startDownloading(of info: ImageInfo) -> Callback<UIImage?>
    func startDownloading(of url: URL) -> Callback<UIImage?>

    func cancelDownloading(of info: [ImageInfo])
    func cancelDownloading(of info: ImageInfo)
    func cancelDownloading(of urls: [URL])
    func cancelDownloading(of url: URL)

    // MARK: - Prefetching

    func startPrefetching(of info: [ImageInfo])
    func startPrefetching(of info: ImageInfo)
    func startPrefetching(of urls: [URL])
    func startPrefetching(of url: URL)

    func cancelPrefetching(of infos: [ImageInfo])
    func cancelPrefetching(of info: ImageInfo)
    func cancelPrefetching(of urls: [URL])
    func cancelPrefetching(of url: URL)

    // MARK: - UIImageView

    func startDownloading(of info: ImageInfo,
                          for imageView: UIImageView) -> Callback<UIImage?>
    func startDownloading(of url: URL,
                          for imageView: UIImageView) -> Callback<UIImage?>

    func cancelDownloading(for imageView: UIImageView)
}

extension Impl {
    final class ImageDownloader<Error: AnyError> {
        private let decodingQueue: Queueable = Queue.custom(label: "ImageDownloader.decodingQueue",
                                                            qos: .utility,
                                                            attributes: .concurrent)
        private typealias Animation = ImageInfo.Animation
        private typealias Priority = ImageInfo.Priority
        private typealias Placeholder = ImageInfo.Placeholder
        private typealias Parameters = NRequest.Parameters

        private class Weakness {
            @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
            private var cached: [() -> UIImageView?] = []

            var views: [UIImageView] {
                return cached.compactMap {
                    return $0()
                }
            }

            var isEmpty: Bool {
                return views.isEmpty
            }

            func add(_ imageView: UIImageView) {
                cached.append { [weak imageView] in
                    return imageView
                }
            }

            func remove(_ imageView: UIImageView) {
                cached = cached.filter {
                    if let cached = $0() {
                        return cached !== imageView
                    }
                    return false
                }
            }
        }

        @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
        private var pending: [URL: PendingCallback<UIImage?>] = [:]
        @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
        private var imageViewCache: [URL: Weakness] = [:]

        private let requestFactory: AnyRequestManager<Error>
        private let imageCache: NImageDownloader.ImageCache
        private let operationQueue: NImageDownloader.ImageDownloadQueue
        private let imageProcessing: NImageDownloader.ImageProcessing
        private let imageDecoding: NImageDownloader.ImageDecoding

        init(requestFactory: AnyRequestManager<Error>,
             imageCache: NImageDownloader.ImageCache,
             operationQueue: NImageDownloader.ImageDownloadQueue,
             imageProcessing: NImageDownloader.ImageProcessing,
             imageDecoding: NImageDownloader.ImageDecoding) {
            self.requestFactory = requestFactory
            self.imageCache = imageCache
            self.imageProcessing = imageProcessing
            self.imageDecoding = imageDecoding
            self.operationQueue = operationQueue
        }

        private func request(with info: ImageInfo) -> Callback<UIImage?> {
            let parameters = Parameters(address: .url(info.url),
                                        requestPolicy: info.cachePolicy,
                                        timeoutInterval: info.timeoutInterval,
                                        queue: .async(decodingQueue))
            let request = requestFactory.requestData(with: parameters)
                .recoverNil()
                .andThen { [imageDecoding] (data: Data?) -> Callback<UIImage?> in
                    if let data = data {
                        return imageDecoding.decode(data)
                    }
                    return .init(result: nil)
                }
                .polling(retryCount: 5,
                         idleTimeInterval: 0,
                         shouldRepeat: { result in
                             return result.1 == nil
                         })
                .beforeComplete { [imageCache] result in
                    if result.1 != nil,
                       let data = result.0 {
                        imageCache.store(data, for: info.url)
                    } else {
                        imageCache.remove(for: info.url)
                    }
                }
                .second()
            return request
        }

        private func add(_ imageView: UIImageView,
                         for url: URL) {
            $imageViewCache.mutate { imageViewCache in
                imageViewCache = imageViewCache.filter { _, view in
                    view.remove(imageView)
                    return !view.isEmpty
                }

                if let container = imageViewCache[url] {
                    container.add(imageView)
                } else {
                    let container: Weakness = .init()
                    container.add(imageView)
                    imageViewCache[url] = container
                }
            }
        }

        private func schedule(_ info: ImageInfo) -> Callback<UIImage?> {
            let pending: PendingCallback<UIImage?> = $pending.mutate { pending in
                let result: PendingCallback<UIImage?>

                if let cached = pending[info.url] {
                    result = cached
                } else {
                    result = .init()
                    result.beforeComplete { [weak self] _ in
                        self?.$pending.mutate {
                            $0[info.url] = nil
                        }
                    }
                    pending[info.url] = result
                }

                return result
            }

            return pending.current { actual in
                self.addOperation(configuration: info, actual: actual)
            }
        }

        private func addOperation(configuration: ImageInfo,
                                  actual: Callback<UIImage?>) {
            let prioritizer: (URL) -> ImageDownloadQueuePriority = { [weak self] url in
                if let imageViewCache = self?.imageViewCache,
                   let cached = imageViewCache[url],
                   !cached.isEmpty {
                    return .hasImageView
                }

                return .preset(configuration.priority)
            }

            // swiftformat:disable:next redundantSelf
            operationQueue.add(requestGenerator: self.request(with: configuration),
                               completionCallback: actual,
                               url: configuration.url,
                               prioritizer: prioritizer)
        }

        private func removeOperation(for url: URL) {
            $pending.mutate { pending in
                pending[url]?.cancel()
            }
            operationQueue.cancel(for: url)
        }

        private func cachedImage(for info: ImageInfo) -> Callback<UIImage?>? {
            if let data = imageCache[info.url] {
                return imageDecoding.decode(data)
                    .andThen { [imageProcessing] image in
                        if let image = image {
                            return imageProcessing.process(image, processors: info.processors).flatMap {
                                return $0
                            }
                        }
                        return .init(result: nil)
                    }
                    .second()
                    .beforeComplete { [imageCache] result in
                        if result == nil {
                            imageCache.remove(for: info.url)
                        }
                    }
            }
            return nil
        }

        private func setToImageViews(_ image: UIImage?,
                                     info: ImageInfo,
                                     cleanup: Bool,
                                     animated: Bool) {
            let selected: [UIImageView]? = $imageViewCache.mutate { imageViewCache in
                let selected = imageViewCache[info.url]?.views

                if cleanup {
                    imageViewCache[info.url] = nil
                }

                return selected
            }

            if let selected = selected, !selected.isEmpty {
                Queue.main.sync {
                    for view in selected {
                        if animated {
                            info.animation.animate(view, image: image)
                        } else {
                            view.image = image
                        }
                    }
                }
            }

            if cleanup {
                removeOperation(for: info.url)
            }
        }

        private func setPlaceholder(to imageView: UIImageView,
                                    info: ImageInfo,
                                    scheduled: Callback<UIImage?>) -> Callback<UIImage?> {
            switch info.placeholder {
            case .ignore:
                return scheduled
            case .clear:
                return .init { actual in
                    Queue.main.sync {
                        imageView.image = nil
                    }

                    actual.waitCompletion(of: scheduled)
                }
            case .image(let placeholder):
                return .init { [imageProcessing] actual in
                    imageProcessing.process(placeholder,
                                            processors: info.processors)
                        .onComplete { placeholder in
                            self.setToImageViews(placeholder,
                                                 info: info,
                                                 cleanup: false,
                                                 animated: false)
                            actual.waitCompletion(of: scheduled)
                        }
                }
            }
        }
    }
}

extension Impl.ImageDownloader: ImageDownloader {
    func startDownloading(of configuration: ImageInfo) -> Callback<UIImage?> {
        assert(Thread.isMainThread)

        if let cachedImage = cachedImage(for: configuration) {
            return cachedImage
        }
        return schedule(configuration)
    }

    func startDownloading(of url: URL) -> Callback<UIImage?> {
        return startDownloading(of: .init(url: url))
    }

    func startDownloading(of info: ImageInfo, for imageView: UIImageView) -> Callback<UIImage?> {
        assert(Thread.isMainThread)
        cancelDownloading(for: imageView)

        if info.cachePolicy.canUseCachedData,
           let image = imageView.image,
           let currentSourceURL = image.sourceURL,
           currentSourceURL == info.url {
            return .init(result: image)
        }

        add(imageView, for: info.url)

        var scheduled: Callback<UIImage?> = .init { actual in
            let scheduled = self.schedule(info)
            scheduled.onComplete { [actual] image in
                self.setToImageViews(image,
                                     info: info,
                                     cleanup: true,
                                     animated: true)
                actual.complete(image)
            }
        }

        if let cachedImage = cachedImage(for: info) {
            let loader = scheduled
            scheduled = cachedImage.andThen { image -> Callback<UIImage?> in
                if let image = image {
                    return .init(result: image)
                } else {
                    return loader
                }
            }
            .second()
            .beforeComplete { image in
                self.setToImageViews(image,
                                     info: info,
                                     cleanup: true,
                                     animated: true)
            }
        }

        return setPlaceholder(to: imageView,
                              info: info,
                              scheduled: scheduled)
    }

    func startDownloading(of url: URL, for imageView: UIImageView) -> Callback<UIImage?> {
        return startDownloading(of: .init(url: url), for: imageView)
    }

    func cancelDownloading(of configurations: [ImageInfo]) {
        let urls = configurations.map(\.url)
        cancelDownloading(of: urls)
    }

    func cancelDownloading(of configuration: ImageInfo) {
        cancelDownloading(of: [configuration.url])
    }

    func cancelDownloading(of urls: [URL]) {
        assert(Thread.isMainThread)

        $imageViewCache.mutate { imageViewCache in
            for url in urls {
                if imageViewCache[url]?.isEmpty == true {
                    removeOperation(for: url)
                }
            }
        }
    }

    func cancelDownloading(of url: URL) {
        cancelDownloading(of: [url])
    }

    func cancelDownloading(for imageView: UIImageView) {
        assert(Thread.isMainThread)

        $imageViewCache.mutate { imageViewCache in
            imageViewCache = imageViewCache.filter { url, view in
                view.remove(imageView)

                if view.isEmpty {
                    removeOperation(for: url)
                }

                return !view.isEmpty
            }
        }
    }

    func startPrefetching(of configurations: [ImageInfo]) {
        for configuration in configurations {
            startDownloading(of: configuration).oneWay()
        }
    }

    func startPrefetching(of configuration: ImageInfo) {
        startPrefetching(of: [configuration])
    }

    func startPrefetching(of urls: [URL]) {
        let infos = urls.map {
            return ImageInfo(url: $0, priority: .prefetch)
        }
        startPrefetching(of: infos)
    }

    func startPrefetching(of url: URL) {
        startPrefetching(of: [url])
    }

    func cancelPrefetching(of configurations: [ImageInfo]) {
        let urls = configurations.map(\.url)
        cancelPrefetching(of: urls)
    }

    func cancelPrefetching(of configuration: ImageInfo) {
        let url = configuration.url
        cancelPrefetching(of: url)
    }

    func cancelPrefetching(of urls: [URL]) {
        cancelDownloading(of: urls)
    }

    func cancelPrefetching(of url: URL) {
        cancelPrefetching(of: [url])
    }
}

private extension Optional where Wrapped == ImageInfo.Animation {
    func animate(_ imageView: UIImageView, image: UIImage?) {
        assert(Thread.isMainThread)
        switch self {
        case .none:
            imageView.image = image
        case .crossDissolve:
            if image?.size == imageView.image?.size,
               let currentSourceURL = imageView.image?.sourceURL,
               image?.sourceURL == currentSourceURL {
                return // No need to animate the same image, it’s already here
            }

            UIView.transition(with: imageView,
                              duration: 0.24,
                              options: [.transitionCrossDissolve, .beginFromCurrentState],
                              animations: {
                                  imageView.image = image
                              })
        }
    }
}
