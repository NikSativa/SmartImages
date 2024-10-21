# SmartImages
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNikSativa%2FSmartImages%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/NikSativa/SmartImages)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNikSativa%2FSmartImages%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/NikSativa/SmartImages)
[![CI](https://github.com/NikSativa/SmartImages/actions/workflows/swift_macos.yml/badge.svg)](https://github.com/NikSativa/SmartImages/actions/workflows/swift_macos.yml)

Simple and lightweight library for loading images in a fast way, because it prioritizes queuing and loading images in the order they are requested and/or if ImageView is waiting for an image to be loaded, it will be prioritized over the others. 
It uses the native Image object to load images and provides a way to cache them in memory and you can also set a custom cache size.

### ImageDownloader
Manager responsible for downloading images from the internet.

### ImageCache
Manager responsible for caching images in memory. 
By default: 
- memory capacity is **40MB** and minimum capacity is **10MB**
- disk capacity is **400MB** and minimum capacity is **10MB**

### ImageDownloadQueue
Manager responsible for queuing images to be downloaded and prioritizing the images that are being requested.
The priority changes at runtime, so it is calculated before adding to the download queue. The highest priority occurs when the image URL is attached to a UI view (SwiftUI is also supported) and has a queued timestamp that is much closer to the current time.

Example:
- You have a queue with a limit of 2 tasks at a time. 
- You add 5 tasks with low priority:

```swift
for i in 0..<5 {
    imageDownloader.prefetch(url: URL(string: "apple.com/image_\(i)")!)
}
```

- `ImageDownloader` is starting download first 2 images immediately.
- You add 2 tasks which are attached to UI-view

```swift
let imageView = UIImageView()
imageView.setImage(withURL: URL(string: "apple.com/image\_\\(99)")!) // new URL
imageView.setImage(withURL: URL(string: "apple.com/image\_\\(3)")!)  // <-- the same URL in queue
```

- `ImageDownloader` did download 1 image and free 1 space in queue. 
- The state is:
    - "image\_1 - downloaded
    - "image\_2" - in progress
    - "image\_3"
    - "image\_4"
    - "image\_5"
    - "image\_3" with View
    - "image\_99" with View 

- Prioritization algorithm will do:
    - "image\_3" with View and added after "99" - that means timestamp is more close to "now" *("now" - "99".timestamp > "now" - "3".timestamp)*
    - "image\_99" with View
    - ~~"image\_1"~~ - downloaded, no longer needed
    - "image\_2" - in progress
    - ~~"image\_3"~~ the same URL as already added "with View"
    - "image\_4"
    - "image\_5"

- Next task will take **"image\_3" with View** because it is attached to View and that means the User is Waiting this image on his screen.

### ImageDownloaderNetwork
Protocol that must be implemented by the app and represents the network layer.

## How to use

Example anywhere in the application:
```swift
planeImageView.setImage(withURL: url, placeholder: .image(.planePlaceholder))
planeImageView.setImage(withURL: url, placeholder: .clear)
planeImageView.setImage(withURL: url)
```

`UIImageView` extension for easy use:
```swift
// extend UIImageView for loading images
public extension UIImageView {
    func setImage(withURL url: URL,
                  animated animation: ImageAnimation? = nil,
                  placeholder: ImagePlaceholder = .none,
                  completion: ImageClosure? = nil) {
        let info = ImageInfo(url: url)
        ImageDownloader.shared.download(of: info,
                                        for: self,
                                        animated: animation,
                                        placeholder: placeholder,
                                        completion: completion ?? { _ in })
    }

    func cancelImageRequest() {
        ImageDownloader.shared.cancel(for: self)
    }
}

// MARK: - ImageDownloader + ImageDownloading

extension ImageDownloader: ImageDownloading {
    public var imageCache: ImageCaching? {
        return Self.shared.imageCache
    }

    public func prefetch(of info: ImageInfo,
                         completion: @escaping ImageClosure) {
        Self.shared.prefetch(of: info, completion: completion)
    }

    public func prefetching(of info: SmartImages.ImageInfo, completion: @escaping SmartImages.ImageClosure) -> AnyCancellable {
        return Self.shared.prefetching(of: info, completion: completion)
    }

    public func download(of info: ImageInfo,
                         completion: @escaping ImageClosure) -> AnyCancellable {
        Self.shared.download(of: info,
                             completion: completion)
    }

    public func download(of info: ImageInfo,
                         for imageView: ImageView,
                         animated animation: ImageAnimation?,
                         placeholder: ImagePlaceholder = .none,
                         completion: @escaping ImageClosure) {
        Self.shared.download(of: info,
                             for: imageView,
                             animated: animation,
                             placeholder: placeholder,
                             completion: completion)
    }

    public func cancel(for imageView: ImageView) {
        Self.shared.cancel(for: imageView)
    }
}
```

### How to use with SmartNetwork

```swift
import Combine
import Foundation
import SmartImages
import SmartNetwork
import UIKit

public typealias ImageAnimation = SmartImages.ImageAnimation
public typealias ImageClosure = SmartImages.ImageClosure
public typealias ImageInfo = SmartImages.ImageInfo
public typealias ImagePlaceholder = SmartImages.ImagePlaceholder

public struct ImageDownloader {
    private static let manager: RequestManagering = RequestManager.create() // <---- this is the place of your custom plugins, StopTheLine etc.

    public static let shared: ImageDownloading = {
        return SmartImages.ImageDownloader(network: ImageDownloaderNetworkAdaptor(manager: manager),
                                           cache: .init(folderName: "DownloadedImages"),
                                           concurrentLimit: 8)
    }()

    private init() {}
}

extension RequestingTask: @retroactive ImageDownloaderTask {}

private struct ImageDownloaderNetworkAdaptor: ImageDownloaderNetwork {
    let manager: RequestManagering

    func request(with url: URL,
                 cachePolicy: URLRequest.CachePolicy?,
                 timeoutInterval: TimeInterval?,
                 completion: @escaping ResultCompletion,
                 finishedOrCancelled finished: FinishedCompletion?) -> ImageDownloaderTask {
        return manager.data.request(address: .init(url),
                                    with: .init(requestPolicy: cachePolicy ?? .useProtocolCachePolicy,
                                                timeoutInterval: timeoutInterval ?? RequestSettings.timeoutInterval),
                                    inQueue: .absent,
                                    completion: completion)
            .autorelease()
            .deferredStart()
    }
}
```

### How to use with URLSession

```swift
import Foundation
import SmartImages
import UIKit

public enum ImageDownloader {
    private static let imageDownloader: ImageDownloading = {
        return SmartImages.ImageDownloader.create(network: ImageDownloaderNetworkAdaptor(),
                                                  cache: .init(folderName: "DownloadedImages"),
                                                  concurrentImagesLimit: 8)
    }()

    public init() {}
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
