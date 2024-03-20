import Combine
import Foundation

#if os(iOS) || os(tvOS) || os(visionOS) || os(watchOS)
import UIKit
#elseif os(macOS)
import Cocoa
#else
#error("unsupported os")
#endif

public protocol ImageDownloading {
    func download(of info: ImageInfo,
                  for imageView: ImageView,
                  animated animation: ImageAnimation?,
                  completion: @escaping ImageClosure)

    func download(of info: ImageInfo,
                  completion: @escaping ImageClosure) -> AnyCancellable
    func predownload(of info: ImageInfo,
                     completion: @escaping ImageClosure)

    func cancel(for imageView: ImageView)
}

public extension ImageDownloading {
    func download(of info: ImageInfo) -> AnyCancellable {
        return download(of: info,
                        completion: { _ in })
    }

    func download(of info: ImageInfo,
                  for imageView: ImageView) {
        download(of: info,
                 for: imageView,
                 animated: nil,
                 completion: { _ in })
    }

    func download(of info: ImageInfo,
                  for imageView: ImageView,
                  animated animation: ImageAnimation) {
        download(of: info,
                 for: imageView,
                 animated: animation,
                 completion: { _ in })
    }

    func download(of info: ImageInfo,
                  for imageView: ImageView,
                  completion: @escaping ImageClosure) {
        download(of: info,
                 for: imageView,
                 animated: nil,
                 completion: completion)
    }

    func download(url: URL,
                  cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                  timeoutInterval: TimeInterval = 60,
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

    func download(url: URL,
                  cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                  timeoutInterval: TimeInterval = 60,
                  processors: [ImageProcessor] = [],
                  priority: ImagePriority = .default,
                  for imageView: ImageView,
                  animated animation: ImageAnimation? = nil,
                  completion: ImageClosure? = nil) {
        let info = ImageInfo(url: url,
                             cachePolicy: cachePolicy,
                             timeoutInterval: timeoutInterval,
                             processors: processors,
                             priority: priority)
        download(of: info,
                 for: imageView,
                 animated: animation,
                 completion: completion ?? { _ in })
    }

    func predownload(of info: ImageInfo) {
        predownload(of: info,
                    completion: { _ in })
    }

    func predownload(url: URL,
                     cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                     timeoutInterval: TimeInterval = 60,
                     processors: [ImageProcessor] = [],
                     priority: ImagePriority = .default,
                     completion: @escaping ImageClosure = { _ in }) {
        let info = ImageInfo(url: url,
                             cachePolicy: cachePolicy,
                             timeoutInterval: timeoutInterval,
                             processors: processors,
                             priority: priority)
        predownload(of: info,
                    completion: completion)
    }
}
