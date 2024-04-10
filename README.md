# SmartImages

Simple and lightweight library for loading images in a fast way, because it prioritizes queuing and loading images in the order they are requested and/or if ImageView is waiting for an image to be loaded, it will be prioritized over the others. 
It uses the native Image object to load images and provides a way to cache them in memory and you can also set a custom cache size.

### ImageDownloader
Manager responsible for downloading images from the internet.

### ImageCache
Manager responsible for caching images in memory.

### ImageDownloadQueue
Manager responsible for queuing images to be downloaded and preoritizing the images that are being requested.

### ImageDownloaderNetwork
Protocol that must be implemented by the app and represents the network layer.

## How to use with URLSession

in app:
```swift
planeImageView.setImage(withURL: url, placeholder: .image(.planePlaceholder))
planeImageView.setImage(withURL: url, placeholder: .clear)
planeImageView.setImage(withURL: url)
```

implementation:
```swift
import Foundation
import NImageDownloader
import UIKit

public enum ImageDownloader {
    private static let imageDownloader: ImageDownloading = {
        return NImageDownloader.ImageDownloader.create(network: ImageDownloaderNetworkAdaptor(),
                                                       cache: .init(folderName: "DownloadedImages"),
                                                       concurrentImagesLimit: 8)
    }()

    public init() {}
}

public extension UIImageView {
    func setImage(withURL url: URL,
                  animated animation: ImageAnimation? = nil,
                  placeholder: ImagePlaceholder = .none,
                  completion: ImageClosure? = nil) {
        let info = ImageInfo(url: url)
        ImageDownloader().download(of: info,
                                   for: self,
                                   animated: animation,
                                   placeholder: placeholder,
                                   completion: completion ?? { _ in })
    }

    func cancelImageRequest() {
        ImageDownloader().cancel(for: self)
    }
}

// MARK: - ImageDownloader + ImageDownloading

extension ImageDownloader: ImageDownloading {
    public var imageCache: ImageCaching? {
        return Self.imageDownloader.imageCache
    }

    public func predownload(of info: ImageInfo,
                            completion: @escaping ImageClosure) {
        Self.imageDownloader.predownload(of: info,
                                         completion: completion)
    }

    public func download(of info: ImageInfo,
                         completion: @escaping ImageClosure) -> AnyCancellable {
        Self.imageDownloader.download(of: info,
                                      completion: completion)
    }

    public func download(of info: ImageInfo,
                         for imageView: ImageView,
                         animated animation: ImageAnimation?,
                         placeholder: ImagePlaceholder = .none,
                         completion: @escaping ImageClosure) {
        Self.imageDownloader.download(of: info,
                                      for: imageView,
                                      animated: animation,
                                      placeholder: placeholder,
                                      completion: completion)
    }

    public func cancel(for imageView: ImageView) {
        Self.imageDownloader.cancel(for: imageView)
    }
}

private struct ImageDownloaderTaskAdaptor: ImageDownloaderTask {
    let task: URLSessionTask

    func start() {
        task.resume()
    }

    func cancel() {
        task.cancel()
    }
}

private struct ImageDownloaderNetworkAdaptor: ImageDownloaderNetwork {
    private let session: URLSession = .shared

    func request(with url: URL,
                 cachePolicy: URLRequest.CachePolicy,
                 timeoutInterval: TimeInterval,
                 completion: @escaping (Result<Data, Error>) -> Void) -> ImageDownloaderTask {
        let dataTask = session.dataTask(with: url) { data, _, error in
            if let error {
                completion(.failure(error))
            } else if let data {
                completion(.success(data))
            } else {
                completion(.failure(NSError(domain: "ImageDownloader", code: 0, userInfo: ["url": url])))
            }
        }

        return ImageDownloaderTaskAdaptor(task: dataTask)
    }
}

```
