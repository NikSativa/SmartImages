# SmartImages

[![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNikSativa%2FSmartImages%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/NikSativa/SmartImages)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNikSativa%2FSmartImages%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/NikSativa/SmartImages)
[![NikSativa CI](https://github.com/NikSativa/SmartImages/actions/workflows/swift_macos.yml/badge.svg)](https://github.com/NikSativa/SmartImages/actions/workflows/swift_macos.yml)

**SmartImages** is a powerful and flexible Swift library that makes loading images fast, smooth, and efficient. Whether you're building a UIKit or SwiftUI app, SmartImages helps you prioritize, download, and cache images intelligently—with minimal setup.

## ✨ Key Features

- **🧠 Intelligent Prioritization**: Images with visible views are automatically prioritized over background downloads
- **💾 Smart Caching**: Configurable memory and disk caching with automatic cleanup
- **⚡ Concurrent Downloads**: Optimized download queue with configurable concurrency limits
- **🔧 Custom Processing**: Built-in support for image processors (resizing, cropping, filters, etc.)
- **🌐 Flexible Networking**: Easy integration with any networking layer (URLSession, Alamofire, etc.)
- **📱 Cross-Platform**: Works seamlessly across iOS, macOS, tvOS, watchOS, and visionOS
- **🎯 Thread-Safe**: All operations are thread-safe and can be used from any queue

---

## ⚡ Quickstart

### Basic Image Loading
```swift
import SmartImages

// Simple image loading with placeholder
imageView.setImage(withURL: URL(string: "https://example.com/image.jpg")!,
                   placeholder: .image(UIImage(systemName: "photo")!),
                   animated: .crossDissolve)
```

### Advanced Configuration
```swift
// Create a downloader with custom settings
// Note: You need to implement ImageDownloaderNetwork protocol
let downloader = ImageDownloader(
    network: YourCustomNetworkImplementation(),
    cache: ImageCacheInfo(folderName: "MyImages"),
    concurrentLimit: 6
)

// Download with custom processing
let info = ImageInfo(
    url: imageURL,
    cachePolicy: .returnCacheDataElseLoad,
    processors: [ImageProcessors.Composition(processors: [
        // Add your custom processors here
    ])],
    priority: .high
)

downloader.download(of: info, completion: { image in
    // Handle loaded image
})
```

### Cancel Downloads
```swift
imageView.cancelImageRequest()
```

---

## 🏗️ Architecture

SmartImages is built with a modular architecture that separates concerns and provides maximum flexibility:

### Core Components

- **`ImageDownloader`** - Main orchestrator that coordinates all image loading operations
- **`ImageDownloaderNetwork`** - Protocol for custom networking implementations  
- **`ImageCache`** - Handles memory and disk caching with configurable limits
- **`ImageDownloadQueue`** - Manages download prioritization and concurrency
- **`ImageProcessor`** - Protocol for image transformations and processing
- **`ImageDecoding`** - Protocol for custom image format decoders

### Key Benefits

- **Performance**: Intelligent prioritization ensures visible images load first
- **Memory Efficient**: Automatic cache management prevents memory issues
- **Flexible**: Easy to customize networking, caching, and processing behavior
- **Reliable**: Thread-safe operations with proper error handling
- **Scalable**: Handles high-volume image loading scenarios efficiently

---

## 🎯 Why Choose SmartImages?

SmartImages is designed for modern iOS/macOS apps that need reliable, efficient image loading:

- **📰 Perfect for Content Apps**: News, social media, e-commerce, and photo-heavy applications
- **🚀 Production Ready**: Battle-tested in real-world applications with comprehensive error handling
- **🔧 Highly Customizable**: Fine-grained control over networking, caching, and processing
- **💡 Developer Friendly**: Clean API design that separates concerns and promotes testability
- **📈 Performance Optimized**: Intelligent prioritization and caching for smooth user experience
- **🛡️ Memory Safe**: Automatic memory management prevents crashes and performance issues

---

## 📚 API Reference

### Core Types

#### `ImageDownloader`
The main class for downloading and managing images. Coordinates networking, caching, and processing operations.

```swift
// Note: You need to implement ImageDownloaderNetwork protocol
// See the Custom Networking Integration example below for details
let downloader = ImageDownloader(
    network: YourCustomNetworkImplementation(),
    cache: ImageCacheInfo(folderName: "MyImages"),
    concurrentLimit: 6
)
```

#### `ImageInfo`
Configuration for image downloads including URL, cache policy, processors, and priority.

```swift
let info = ImageInfo(
    url: imageURL,
    cachePolicy: .returnCacheDataElseLoad,
    processors: [customProcessor],
    priority: .high
)
```

#### `ImageCacheInfo`
Cache configuration with customizable memory and disk limits.

```swift
let cache = ImageCacheInfo(
    folderName: "MyAppImages",
    memoryCapacity: 80 * 1024 * 1024,  // 80MB
    diskCapacity: 800 * 1024 * 1024     // 800MB
)
```

#### `ImagePlaceholder`
Placeholder options for showing content while images load.

```swift
let placeholder = ImagePlaceholder.image(UIImage(systemName: "photo")!)
let placeholder = ImagePlaceholder.imageNamed("placeholder")
let placeholder = ImagePlaceholder.clear
```

#### `ImagePriority`
Download priority levels for optimizing load order.

```swift
let priority = ImagePriority.high  // Critical UI elements
let priority = ImagePriority.prefetch  // Background loading
```

#### `ImageProcessor`
Protocol for image transformations during download.

```swift
struct ResizeProcessor: ImageProcessor {
    func process(_ image: Image) -> Image {
        // Resize implementation
    }
}
```

---

## 💡 Advanced Usage Examples

### Image Loading with Custom Processing
```swift
// Create a custom processor for image resizing
struct ResizeProcessor: ImageProcessor {
    let targetSize: CGSize
    
    func process(_ image: Image) -> Image {
        // Implementation for resizing image to target size
        return resizedImage
    }
}

// Use with ImageInfo
let info = ImageInfo(
    url: imageURL,
    processors: [ResizeProcessor(targetSize: CGSize(width: 200, height: 200))],
    priority: .high
)

downloader.download(of: info, completion: { image in
    DispatchQueue.main.async {
        imageView.image = image
    }
})
```

### Prefetching Images
```swift
// Prefetch images for better user experience
let prefetchInfo = ImageInfo(
    url: upcomingImageURL,
    priority: .prefetch
)

downloader.prefetch(of: prefetchInfo) { image in
    // Image is now cached and ready to display
}
```

### Custom Networking Integration
```swift
// Implement custom networking for authentication, headers, etc.
struct YourCustomNetworkImplementation: ImageDownloaderNetwork {
    func request(with url: URL, 
                cachePolicy: URLRequest.CachePolicy?, 
                timeoutInterval: TimeInterval?, 
                completion: @escaping ResultCompletion) -> ImageDownloaderTask {
        var request = URLRequest(url: url)
        request.cachePolicy = cachePolicy ?? .useProtocolCachePolicy
        request.timeoutInterval = timeoutInterval ?? 30
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                completion(.success(data))
            } else if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(NSError(domain: "ImageDownloaderNetwork", code: -1)))
            }
        }

        return URLSessionTaskAdaptor(task: task)
    }
}

// Adaptor to make URLSessionDataTask conform to ImageDownloaderTask
private final class URLSessionTaskAdaptor: ImageDownloaderTask {
    private let task: URLSessionDataTask
    
    init(task: URLSessionDataTask) {
        self.task = task
    }
    
    func start() {
        task.resume()
    }
    
    func cancel() {
        task.cancel()
    }
}

let downloader = ImageDownloader(network: YourCustomNetworkImplementation())
```

### SwiftUI Integration
```swift
struct AsyncImageView: View {
    let url: URL
    @State private var image: Image?
    @State private var holder: ImageDownloadReference = .init()

    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            downloader.download(of: ImageInfo(url: url), 
                              for: holder,
                              placeholder: .clear) { loadedImage in
                image = loadedImage
            }
        }
    }
}
```

---

## 🧩 Integrating SmartImages

### Swift Package Manager (Recommended)
1. In Xcode, go to **File > Add Packages...**
2. Use the URL:
   ```
   https://github.com/NikSativa/SmartImages.git
   ```
3. Select the latest version and click **Add Package**.

Then just import:
```swift
import SmartImages
```

---

## ⚙️ Configuration Options

### Cache Configuration
```swift
// Default cache settings (40MB memory, 400MB disk)
let cache = ImageCacheInfo(folderName: "MyAppImages")

// Custom cache sizes
let cache = ImageCacheInfo(
    folderName: "LargeCache",
    memoryCapacity: 100 * 1024 * 1024,  // 100MB
    diskCapacity: 1000 * 1024 * 1024     // 1GB
)

// Custom cache directory
let cache = ImageCacheInfo(
    directory: customCacheDirectory,
    memoryCapacity: 50 * 1024 * 1024,
    diskCapacity: 500 * 1024 * 1024
)
```

### Download Concurrency
```swift
// Limit concurrent downloads for better performance
let downloader = ImageDownloader(
    network: YourCustomNetworkImplementation(),
    concurrentLimit: 4  // Only 4 downloads at once
)

// Unlimited downloads (use with caution)
let downloader = ImageDownloader(
    network: YourCustomNetworkImplementation(),
    concurrentLimit: nil  // No limit
)
```

### Image Processing Pipeline
```swift
// Chain multiple processors
let processors = [
    ResizeProcessor(size: CGSize(width: 300, height: 300)),
    RoundCornersProcessor(radius: 10),
    BlurProcessor(radius: 1.0)
]

let composition = ImageProcessors.Composition(processors: processors)
let info = ImageInfo(url: imageURL, processors: [composition])
```

---

## ✅ Supported Platforms

SmartImages supports all modern Apple platforms with consistent APIs:

- **iOS 13+** - Full feature support including animations and UIKit integration
- **macOS 11+** - Complete macOS support with AppKit integration  
- **macCatalyst 13+** - Seamless iPad apps running on Mac
- **tvOS 13+** - Optimized for TV interface and remote navigation
- **watchOS 6+** - Lightweight implementation for Apple Watch
- **visionOS 1+** - Full support for visionOS applications

### Swift Version Support
- **Swift 5.9+** - Full compatibility with modern Swift features
- **Swift 6.0+** - Enhanced concurrency support with `Sendable` protocols

---

## 📄 License

SmartImages is available under the MIT license. See the `LICENSE` file for details.

---

## 🧪 Testing

SmartImages includes comprehensive tests covering:

- Image downloading and caching functionality
- Network error handling and retry logic  
- Memory management and leak prevention
- Thread safety and concurrent operations
- Custom processor and decoder implementations

Run tests locally:
```bash
swift test
```

---

## 🙌 Contributing

We welcome contributions to make SmartImages even better! Here's how to get started:

### Getting Started
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes and add tests
4. Run the test suite (`swift test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Development Guidelines
- Follow Swift API Design Guidelines
- Add comprehensive tests for new features
- Update documentation for API changes
- Ensure all tests pass before submitting PR

---

## 📬 Stay Connected

- ⭐️ **Star the repo** to show support and get updates
- 🐛 **Report issues** if you find bugs or have suggestions
- 💬 **Join discussions** in GitHub Discussions
- 👨‍💻 **Follow [@NikSativa](https://github.com/NikSativa)** for more open-source Swift projects

---

## 📈 Performance Tips

For optimal performance in your app:

- **Set appropriate cache limits** based on your app's memory constraints
- **Use prefetching** for images that will likely be viewed soon
- **Implement custom processors** to resize images appropriately for your UI
- **Monitor memory usage** and adjust cache settings as needed
- **Use priority levels** to ensure critical images load first
