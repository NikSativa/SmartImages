import Foundation
import SmartImages

#if os(iOS) || os(tvOS) || supportsVisionOS || os(watchOS)
import UIKit
#elseif os(macOS)
import Cocoa
#else
#error("unsupported os")
#endif

#if swift(>=6.0)
/// A protocol extending `ImageFetching` with UIKit-specific behavior for image views.
///
/// When the reference is a `UIImageView` (or `NSImageView` on macOS), this protocol
/// automatically sets placeholders before downloading and animates image transitions
/// after the download completes.
public protocol ImageViewDownloading: ImageFetching {
    /// Downloads an image with the specified info, sets placeholder and animates the result into the image view.
    func download(of request: ImageRequest,
                  for reference: ImageReference,
                  animated animation: ImageAnimation?,
                  placeholder: ImagePlaceholder,
                  completion: @escaping ImageClosure)
}
#else
/// A protocol extending `ImageFetching` with UIKit-specific behavior for image views.
///
/// When the reference is a `UIImageView` (or `NSImageView` on macOS), this protocol
/// automatically sets placeholders before downloading and animates image transitions
/// after the download completes.
public protocol ImageViewDownloading: ImageFetching {
    /// Downloads an image with the specified info, sets placeholder and animates the result into the image view.
    func download(of request: ImageRequest,
                  for reference: ImageReference,
                  animated animation: ImageAnimation?,
                  placeholder: ImagePlaceholder,
                  completion: @escaping ImageClosure)
}
#endif

// MARK: - Convenience

public extension ImageViewDownloading {
    /// Downloads an image with the specified info and sets it to the image view.
    func download(ofRequest request: ImageRequest,
                  for imageView: SmartImageView,
                  animated animation: ImageAnimation? = nil,
                  placeholder: ImagePlaceholder = .default,
                  completion: ImageClosure? = nil) {
        download(of: request,
                 for: imageView,
                 animated: animation,
                 placeholder: placeholder,
                 completion: completion ?? { _ in })
    }

    /// Downloads an image with URL and sets it to the image view.
    func download(url: URL,
                  cachePolicy: URLRequest.CachePolicy? = nil,
                  timeoutInterval: TimeInterval? = nil,
                  processors: [ImageProcessor] = [],
                  priority: FetchPriority = .default,
                  for imageView: SmartImageView,
                  animated animation: ImageAnimation? = nil,
                  placeholder: ImagePlaceholder = .none,
                  completion: ImageClosure? = nil) {
        let request = ImageRequest(url: url,
                                   cachePolicy: cachePolicy,
                                   timeoutInterval: timeoutInterval,
                                   processors: processors,
                                   priority: priority)
        download(of: request,
                 for: imageView,
                 animated: animation,
                 placeholder: placeholder,
                 completion: completion ?? { _ in })
    }
}
