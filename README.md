# SmartImages

[![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNikSativa%2FSmartImages%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/NikSativa/SmartImages)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNikSativa%2FSmartImages%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/NikSativa/SmartImages)
[![NikSativa CI](https://github.com/NikSativa/SmartImages/actions/workflows/swift_macos.yml/badge.svg)](https://github.com/NikSativa/SmartImages/actions/workflows/swift_macos.yml)

**SmartImages** is a powerful and flexible Swift library that makes loading images fast, smooth, and efficient. Whether you're building a UIKit or SwiftUI app, SmartImages helps you prioritize, download, and cache images intelligently—with minimal setup.

---

## ⚡ Quickstart

Here's how to load an image into a `UIImageView` with a placeholder:

```swift
import SmartImages

imageView.setImage(withURL: URL(string: "https://example.com/image.jpg")!,
                   placeholder: .image(.defaultPlaceholder),
                   animated: .fade(duration: 0.3))
```

You can also cancel requests:
```swift
imageView.cancelImageRequest()
```

---

## 🚀 Features

- ⚡ Prioritized downloads (e.g., on-screen images are prioritized)
- 🧠 Efficient memory and disk caching
- 📱 Works with both UIKit and SwiftUI
- 🔧 Easy integration with your own networking layer
- ⏱ Configurable download concurrency and caching limits
- 🔄 Prefetching support for a smoother experience

---

## 🎯 Why Use SmartImages?

- Ideal for image-heavy apps like news, social, or e-commerce.
- Handles memory pressure gracefully with caching.
- Provides fine control over download performance.
- Decouples your UI code from image loading logic.

---

## 🧰 Core Components

### `ImageDownloader`
Coordinates all image loading logic: networking, caching, and queuing.

### `ImageCache`
Stores images in memory and disk with the following defaults:
- **Memory**: 40MB
- **Disk**: 400MB

### `ImageDownloadQueue`
Handles prioritization and concurrency of downloads—favoring what’s currently visible.

### `ImageDownloaderNetwork`
A protocol you implement to plug in `URLSession`, Alamofire, or any custom networking layer.

---

## 💡 Usage Examples

### Set an image with placeholder:
```swift
imageView.setImage(withURL: url, placeholder: .image(.defaultPlaceholder))
```

### Set image with fade animation:
```swift
imageView.setImage(withURL: url, animated: .fade(duration: 0.3))
```

### Cancel an image request:
```swift
imageView.cancelImageRequest()
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

## ⚙️ Custom Networking

You can use your preferred networking system by implementing the `ImageDownloaderNetwork` protocol. Here’s how to wire it up with either:

### SmartNetwork
```swift
let customDownloader = ImageDownloader(
    network: ImageDownloaderNetworkAdaptor(manager: RequestManager.create()),
    cache: .init(folderName: "DownloadedImages"),
    concurrentLimit: 8
)
```

### URLSession
```swift
let customDownloader = ImageDownloader.create(
    network: ImageDownloaderNetworkAdaptor(),
    cache: .init(folderName: "DownloadedImages"),
    concurrentImagesLimit: 8
)
```

---

## ✅ Supported Platforms

- iOS 13+
- macOS 11+
- macCatalyst 13+
- tvOS 13+
- watchOS 6+
- visionOS 1+

---

## 📄 License

SmartImages is available under the MIT license. See the `LICENSE` file for details.

---

## 🙌 Contributing

We welcome contributions! Feel free to open an issue or PR. To get started:

- Fork the repo
- Make your changes
- Submit a pull request

---

## 📬 Stay Connected

Star ⭐️ the repo to show support and get updates. Follow [@NikSativa](https://github.com/NikSativa) for more open-source Swift projects.
