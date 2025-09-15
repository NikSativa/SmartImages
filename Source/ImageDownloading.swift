import Combine
import Foundation

#if os(iOS) || os(tvOS) || supportsVisionOS || os(watchOS)
import UIKit
#elseif os(macOS)
import Cocoa
#else
#error("unsupported os")
#endif

#if swift(>=6.0)
/// A protocol representing the behavior of downloading images asynchronously.
public protocol ImageDownloading: Sendable {
    /// any object when referencing the downloading task
    /// at UIKit can be UIImageView
    /// at SwiftUI can be ImageReference `@State var reference: ImageReference = .init()`
    typealias ImageReference = AnyObject

    /// The image cache used for downloaded images.
    var imageCache: ImageCaching? { get }

    /// Downloads an image with the specified info and sets it to the image view.
    func download(of info: ImageInfo,
                  for reference: ImageReference,
                  animated animation: ImageAnimation?,
                  placeholder: ImagePlaceholder,
                  completion: @escaping ImageClosure)

    /// Downloads an image with the specified info.
    func download(of info: ImageInfo, completion: @escaping ImageClosure) -> AnyCancellable

    /// Prefetches an image with the specified info.
    func prefetch(of info: ImageInfo, completion: @escaping ImageClosure)

    /// Prefetches an image with the specified info.
    func prefetching(of info: ImageInfo, completion: @escaping ImageClosure) -> AnyCancellable

    /// Cancels the download for the specified image view.
    func cancel(for reference: ImageReference)
}
#else
/// A protocol representing the behavior of downloading images asynchronously.
public protocol ImageDownloading {
    /// any object when referencing the downloading task
    /// at UIKit can be UIImageView
    /// at SwiftUI can be ImageReference `@State var reference: ImageReference = .init()`
    typealias ImageReference = AnyObject

    /// The image cache used for downloaded images.
    var imageCache: ImageCaching? { get }

    /// Downloads an image with the specified info and sets it to the image view.
    func download(of info: ImageInfo,
                  for reference: ImageReference,
                  animated animation: ImageAnimation?,
                  placeholder: ImagePlaceholder,
                  completion: @escaping ImageClosure)

    /// Downloads an image with the specified info.
    func download(of info: ImageInfo, completion: @escaping ImageClosure) -> AnyCancellable

    /// Prefetches an image with the specified info.
    func prefetch(of info: ImageInfo, completion: @escaping ImageClosure)

    /// Prefetches an image with the specified info.
    func prefetching(of info: ImageInfo, completion: @escaping ImageClosure) -> AnyCancellable

    /// Cancels the download for the specified image view.
    func cancel(for reference: ImageReference)
}
#endif

public extension ImageDownloading {
    /// Downloads an image with the specified info.
    func download(of info: ImageInfo) -> AnyCancellable {
        return download(of: info, completion: { _ in })
    }

    /// Downloads an image with the specified info and sets it to the image view.
    func download(ofInfo info: ImageInfo,
                  for imageView: ImageView,
                  animated animation: ImageAnimation? = nil,
                  placeholder: ImagePlaceholder = .default,
                  completion: ImageClosure? = nil) {
        download(of: info,
                 for: imageView,
                 animated: nil,
                 placeholder: placeholder,
                 completion: completion ?? { _ in })
    }

    /// Downloads an image with URL and sets it to the image view.
    func download(url: URL,
                  cachePolicy: URLRequest.CachePolicy? = nil,
                  timeoutInterval: TimeInterval? = nil,
                  processors: [ImageProcessor] = [],
                  priority: ImagePriority = .default,
                  completion: ImageClosure? = nil) -> AnyCancellable {
        let info = ImageInfo(url: url,
                             cachePolicy: cachePolicy,
                             timeoutInterval: timeoutInterval,
                             processors: processors,
                             priority: priority)
        return download(of: info,
                        completion: completion ?? { _ in })
    }

    /// Downloads an image with URL and sets it to the image view.
    func download(url: URL,
                  cachePolicy: URLRequest.CachePolicy? = nil,
                  timeoutInterval: TimeInterval? = nil,
                  processors: [ImageProcessor] = [],
                  priority: ImagePriority = .default,
                  for imageView: ImageView,
                  animated animation: ImageAnimation? = nil,
                  placeholder: ImagePlaceholder = .none,
                  completion: ImageClosure? = nil) {
        let info = ImageInfo(url: url,
                             cachePolicy: cachePolicy,
                             timeoutInterval: timeoutInterval,
                             processors: processors,
                             priority: priority)
        download(of: info,
                 for: imageView,
                 animated: animation,
                 placeholder: placeholder,
                 completion: completion ?? { _ in })
    }

    /// Prefetches an image with the specified info.
    func prefetch(of info: ImageInfo) {
        prefetch(of: info, completion: { _ in })
    }

    /// Prefetches an image with the URL.
    func prefetch(url: URL,
                  cachePolicy: URLRequest.CachePolicy? = nil,
                  timeoutInterval: TimeInterval? = nil,
                  processors: [ImageProcessor] = [],
                  priority: ImagePriority = .prefetch,
                  completion: @escaping ImageClosure = { _ in }) {
        let info = ImageInfo(url: url,
                             cachePolicy: cachePolicy,
                             timeoutInterval: timeoutInterval,
                             processors: processors,
                             priority: priority)
        prefetch(of: info, completion: completion)
    }

    /// Prefetches an image with the URL.
    func prefetching(url: URL,
                     cachePolicy: URLRequest.CachePolicy? = nil,
                     timeoutInterval: TimeInterval? = nil,
                     processors: [ImageProcessor] = [],
                     priority: ImagePriority = .prefetch,
                     completion: @escaping ImageClosure = { _ in }) -> AnyCancellable {
        let info = ImageInfo(url: url,
                             cachePolicy: cachePolicy,
                             timeoutInterval: timeoutInterval,
                             processors: processors,
                             priority: priority)
        return prefetching(of: info, completion: completion)
    }
}
