# SmartImages

[![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNikSativa%2FSmartImages%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/NikSativa/SmartImages)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNikSativa%2FSmartImages%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/NikSativa/SmartImages)
[![NikSativa CI](https://github.com/NikSativa/SmartImages/actions/workflows/swift_macos.yml/badge.svg)](https://github.com/NikSativa/SmartImages/actions/workflows/swift_macos.yml)

**SmartImages** is a modular Swift library for intelligent image loading with prioritization, caching, and processing. The framework is split into three independent targets so you only import what you need.

## Modular Architecture

```
SmartImages          — Core: fetching, caching, decoding, processing
SmartImagesUIKit     — UIKit: placeholder, animation, ImageView extensions
SmartImagesSwiftUI   — SwiftUI: SmartImageView (phase-builder + content-scale)
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
    .package(url: "https://github.com/NikSativa/SmartImages.git", from: "4.0.0")
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

`SmartImageView` is a single generic view with two API modes.

#### Convenience: placeholder + loader + content scale

```swift
import SmartImagesSwiftUI

SmartImageView(url: imageURL,
               imageFetcher: fetcher,
               contentScale: .scaledToFill) {
    ProgressView()
} placeholder: {
    Color.gray
}
```

#### Phase-builder (full control, à la `AsyncImage`)

```swift
SmartImageView(url: imageURL, imageFetcher: fetcher) { phase in
    switch phase {
    case .idle, .loading:
        ProgressView()
    case .loaded(let image, _):
        image.resizable().scaledToFit()
    case .failed, .noURL:
        Image(systemName: "photo")
    }
}
```

#### Inject a default fetcher via environment

Skip `imageFetcher:` on every call site by injecting once at the root:

```swift
@main
struct MyApp: App {
    let fetcher = ImageFetcher(network: YourNetworkImpl())

    var body: some Scene {
        WindowGroup {
            ContentView()
                .smartImageFetcher(fetcher)
        }
    }
}

// anywhere downstream:
SmartImageView(url: url) { phase in /* … */ }
```

### Core (closure-based)

```swift
import SmartImages

let token = fetcher.download(of: ImageRequest(url: imageURL)) { result in
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
fetcher.prefetch(of: ImageRequest(url: upcomingURL, priority: .prefetch)) { _ in }
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

### `ImageRequest`

Configuration for a single download.

```swift
let request = ImageRequest(
    url: imageURL,
    cachePolicy: .returnCacheDataElseLoad,
    timeoutInterval: 30,
    headers: ["Authorization": "Bearer \(token)"],
    processors: [
        ImageProcessors.Resize(size: CGSize(width: 200, height: 200),
                               contentMode: .aspectFill),
        ImageProcessors.Crop(rect: CGRect(x: 0, y: 0, width: 200, height: 200))
    ],
    priority: .high
)
```

### `ImageCacheConfiguration`

Cache configuration. `URLCache` handles size-based LRU eviction; the optional `ttl` adds age-based eviction on read.

```swift
// defaults: 40 MB memory, 400 MB disk
let cache = ImageCacheConfiguration(folderName: "MyAppImages")

// custom limits + TTL
let cache = ImageCacheConfiguration(
    folderName: "LargeCache",
    memoryCapacity: 100 * 1024 * 1024,
    diskCapacity: 1000 * 1024 * 1024,
    ttl: 60 * 60 * 24 * 7   // 7 days
)
```

### `ImageProcessor`

Protocol for image transformations applied during download.

```swift
struct RoundCornersProcessor: ImageProcessor {
    let radius: CGFloat
    func process(_ image: SmartImage) -> SmartImage {
        // transform logic
    }
}
```

#### Built-in processors

```swift
ImageProcessors.Resize(size: CGSize(width: 200, height: 200),
                       contentMode: .aspectFit)   // .stretch / .aspectFit / .aspectFill

ImageProcessors.Crop(rect: CGRect(x: 0, y: 0, width: 200, height: 200))

// chain multiple processors
ImageProcessors.Composition(processors: [
    ImageProcessors.Resize(size: ...),
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

## SwiftUI

### `SmartImageView<Content>`

A single generic view backed by a `(SmartImagePhase) -> Content` builder. Convenience initializers cover the common cases by constructing a `SmartImageContent` renderer for you.

Phase enum:

```swift
public enum SmartImagePhase {
    case idle
    case loading
    case loaded(SwiftUI.Image, nativeSize: CGSize)
    case failed
    case noURL
}
```

### `SmartImageContentScale`

Used by the convenience initializers. Equivalent to `UIView.ContentMode` for the loaded image.

| Case | Behaviour |
|------|-----------|
| `.scaledToFit` | Aspect-fit inside the container (default) |
| `.scaledToFill` | Aspect-fill, may crop |
| `.stretch` | Resizable, ignores aspect |
| `.original` | Natural size, no `.resizable()` |
| `.scaleDown` | `.scaledToFit` clamped to the image's native size — never upscales |

### Environment modifiers

| Modifier | Purpose |
|----------|---------|
| `.smartImageFetcher(_:)` | Default `ImageFetching` for descendant `SmartImageView`s |
| `.smartImageAnimation(_:)` | `Animation` applied when phase transitions to `.loaded` |
| `.smartImageTransition(_:)` | `AnyTransition` applied to the loaded branch |
| `.smartImageTransition(_:animation:)` | Convenience: both at once |

```swift
ContentView()
    .smartImageFetcher(fetcher)
    .smartImageTransition(.opacity, animation: .easeInOut(duration: 0.24))
```

### Previews and tests: `PreviewImageFetcher`

A drop-in `ImageFetching` implementation that returns a deterministic result without performing real I/O.

```swift
#Preview {
    SmartImageView(url: previewURL,
                   imageFetcher: PreviewImageFetcher(image: .init(named: "sample")!),
                   contentScale: .scaledToFit) {
        ProgressView()
    } placeholder: {
        Color.gray
    }
}

// per-URL responses
let fetcher = PreviewImageFetcher(images: [
    url1: image1,
    url2: image2
])

// always fail
let fetcher = PreviewImageFetcher(error: URLError(.notConnectedToInternet))

// simulate latency
let fetcher = PreviewImageFetcher(image: image, delay: 1.5)
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

    // Optional: opt in to ImageRequest.headers by overriding the default
    func request(with url: URL,
                 cachePolicy: URLRequest.CachePolicy?,
                 timeoutInterval: TimeInterval?,
                 headers: [String: String]?,
                 completion: @escaping ResultCompletion) -> ImageNetworkTask {
        // build a URLRequest, attach `headers`, dispatch it
    }
}
```

If you don't override the `headers:` method, the default implementation forwards to the legacy 3-arg method and silently drops headers — useful for keeping older provider implementations source-compatible.

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

private struct ImageDownloaderTaskAdaptor: ImageNetworkTask, @unchecked Sendable {
    let task: SmartTasking

    func start() {
        task.start()
    }

    func cancel() {
        // no-op. auto-cancel on deinit
    }
}
```

## Migration to 4.0

### SwiftUI

| Pre-4.0 | 4.0 |
|---------|-----|
| `AsyncImageView(url:imageDownloader:...)` | `SmartImageView(url:imageFetcher:...)` |
| `SmartImagePhaseView` | merged into `SmartImageView` |
| `SmartImageStyle` / `SmartImageStyleConfiguration` | removed; use `SmartImageContent<P, L>` or supply your own phase-builder |
| `SmartImagePlaceholder` | renamed to `SmartImageResourceView` |
| `case .loaded(SwiftUI.Image)` | `case .loaded(SwiftUI.Image, nativeSize: CGSize)` |

### Core

| Pre-4.0 | 4.0 |
|---------|-----|
| `ImageLoadConfiguration` | `ImageRequest` (now also carries `headers`) |

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
