# SmartImages

[![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNikSativa%2FSmartImages%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/NikSativa/SmartImages)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNikSativa%2FSmartImages%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/NikSativa/SmartImages)
[![NikSativa CI](https://github.com/NikSativa/SmartImages/actions/workflows/swift_macos.yml/badge.svg)](https://github.com/NikSativa/SmartImages/actions/workflows/swift_macos.yml)

**SmartImages** is a modular Swift library for intelligent image loading with prioritization, caching, and processing. The framework is split into three independent targets so you only import what you need.

## Modular Architecture

```
SmartImages          — Core: fetching, caching, decoding, processing
SmartImagesUIKit     — UIKit: placeholder, animation, ImageView extensions
SmartImagesSwiftUI   — SwiftUI: AsyncImageView
```

| You need | Import |
|----------|--------|
| Only protocols and core engine | `SmartImages` |
| UIKit image views with placeholders and animations | `SmartImagesUIKit` |
| SwiftUI async image view | `SmartImagesSwiftUI` |

UIKit and SwiftUI targets depend on `SmartImages` — it is pulled in automatically.

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/NikSativa/SmartImages.git", from: "1.0.0")
]
```

Add only the targets you need:

```swift
.target(name: "YourApp", dependencies: [
    "SmartImagesUIKit",     // UIKit app
    // or
    "SmartImagesSwiftUI",   // SwiftUI app
    // or
    "SmartImages",          // core only (library / module)
])
```

## Quick Start

### UIKit

```swift
import SmartImagesUIKit

let fetcher = ImageFetcher(
    network: YourNetworkImpl(),
    cache: ImageCacheConfiguration(folderName: "MyImages"),
    concurrentLimit: 6
)

// one-liner with placeholder and animation
fetcher.download(url: imageURL,
                 for: imageView,
                 animated: .crossDissolve,
                 placeholder: .image(UIImage(systemName: "photo")!))
```

### SwiftUI

```swift
import SmartImagesSwiftUI

AsyncImageView(url: imageURL, imageDownloader: fetcher) {
    ProgressView()
} placeholder: {
    Image(systemName: "photo")
}
```

### Core (closure-based)

```swift
import SmartImages

let token = fetcher.download(of: ImageLoadConfiguration(url: imageURL)) { result in
    switch result {
    case .success(let image): break // use image
    case .failure(let error): break // handle error
    }
}
// token.cancel() to cancel
```

### Async/Await

```swift
let image = try await fetcher.download(url: imageURL, priority: .high)
```

### Prefetching

```swift
fetcher.prefetch(of: ImageLoadConfiguration(url: upcomingURL, priority: .prefetch)) { _ in }
```

## Core Types

### `ImageFetcher`

The main class that coordinates networking, caching, decoding, and queuing.

```swift
let fetcher = ImageFetcher(
    network: YourNetworkImpl(),          // required
    cache: ImageCacheConfiguration(...), // optional
    decoders: [CustomDecoder()],         // optional
    decodingQueue: .async(.background),  // optional
    concurrentLimit: 6                   // optional
)
```

### `ImageLoadConfiguration`

Configuration for a single download.

```swift
let config = ImageLoadConfiguration(
    url: imageURL,
    cachePolicy: .returnCacheDataElseLoad,
    processors: [ResizeProcessor(targetSize: CGSize(width: 200, height: 200))],
    priority: .high
)
```

### `ImageCacheConfiguration`

Cache configuration.

```swift
// defaults: 40 MB memory, 400 MB disk
let cache = ImageCacheConfiguration(folderName: "MyAppImages")

// custom limits
let cache = ImageCacheConfiguration(
    folderName: "LargeCache",
    memoryCapacity: 100 * 1024 * 1024,
    diskCapacity: 1000 * 1024 * 1024
)
```

### `ImageProcessor`

Protocol for image transformations applied during download.

```swift
struct ResizeProcessor: ImageProcessor {
    let targetSize: CGSize
    func process(_ image: SmartImage) -> SmartImage {
        // resize logic
    }
}

// chain multiple processors
let composition = ImageProcessors.Composition(processors: [
    ResizeProcessor(targetSize: ...),
    RoundCornersProcessor(radius: 10)
])
```

### `FetchPriority`

Download priority levels.

| Priority | Use case |
|----------|----------|
| `.veryHigh` | Visible on screen right now |
| `.high` | About to appear |
| `.normal` | Default |
| `.low` | Background work |
| `.prefetch` | Speculative preload |

### `ImagePlaceholder` (UIKit)

```swift
.image(UIImage(systemName: "photo")!)
.imageNamed("placeholder", bundle: .main)
.clear
.custom { imageView in imageView.backgroundColor = .gray }
.none
```

### `ImageAnimation` (UIKit)

```swift
.crossDissolve                        // iOS/tvOS
.custom { imageView, image in ... }   // all platforms
```

### Custom Networking

Implement `ImageNetworkProvider` and `ImageNetworkTask`:

```swift
struct MyNetwork: ImageNetworkProvider {
    func request(with url: URL,
                 cachePolicy: URLRequest.CachePolicy?,
                 timeoutInterval: TimeInterval?,
                 completion: @escaping ResultCompletion) -> ImageNetworkTask {
        // your networking logic
    }
}
```

#### Integration with [SmartNetwork](https://github.com/NikSativa/SmartNetwork)

```swift
import SmartImages
import SmartNetwork

struct ImageDownloaderNetworkAdaptor: ImageNetworkProvider {
    let manager: RequestManager

    func request(with url: URL,
                 cachePolicy: URLRequest.CachePolicy?,
                 timeoutInterval: TimeInterval?,
                 completion: @escaping ResultCompletion) -> ImageNetworkTask {
        let address: SmartURL = .init(url)
        let parameters: Parameters = .init(requestPolicy: cachePolicy ?? .useProtocolCachePolicy,
                                           timeoutInterval: timeoutInterval ?? 30)
        let task = manager.data
            .request(url: address, with: parameters)
            .complete(in: .absent, completion: completion)
        return ImageDownloaderTaskAdaptor(task: task)
    }
}

private struct ImageDownloaderTaskAdaptor: ImageDownloaderTask, @unchecked Sendable {
    let task: SmartTasking

    func start() {
        task.start()
    }

    func cancel() {
        // no-op. auto-cancel on deinit
    }
}
```

## Migration from pre-2.0

All types have been renamed for clarity. Old names are available as deprecated typealiases:

| Old Name | New Name |
|----------|----------|
| `Image` | `SmartImage` |
| `ImageView` | `SmartImageView` |
| `ImageDownloader` | `ImageFetcher` |
| `ImageDownloading` | `ImageFetching` |
| `ImageInfo` | `ImageLoadConfiguration` |
| `ImageCacheInfo` | `ImageCacheConfiguration` |
| `ImagePriority` | `FetchPriority` |
| `ImageDownloaderNetwork` | `ImageNetworkProvider` |
| `ImageDownloaderTask` | `ImageNetworkTask` |
| `ImageDownloadQueueing` | `ImageQueueScheduling` |
| `ImageDownloadQueuePriority` | `FetchQueueingPriority` |
| `ImageDownloaderError` | `ImageFetchingError` |

## Supported Platforms

| Platform | Minimum |
|----------|---------|
| iOS | 16.0 |
| macOS | 14.0 |
| Mac Catalyst | 16.0 |
| tvOS | 16.0 |
| watchOS | 9.0 |
| visionOS | 1.0 |

- **Swift 5.10+** — full compatibility
- **Swift 6.0+** — strict concurrency with `Sendable`

## Testing

```bash
swift test
```
