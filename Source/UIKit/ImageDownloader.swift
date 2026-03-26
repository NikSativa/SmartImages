import Foundation
import SmartImages
import Threading

#if os(iOS) || os(tvOS) || os(watchOS) || supportsVisionOS
import UIKit
#elseif os(macOS)
import Cocoa
#else
#error("unsupported os")
#endif

// MARK: - ImageViewDownloading

extension ImageFetcher: ImageViewDownloading {
    public func download(of request: ImageRequest,
                         for reference: ImageFetching.ImageReference,
                         animated animation: ImageAnimation?,
                         placeholder: ImagePlaceholder,
                         completion: @escaping ImageClosure) {
        let unsafeReference: USendable = .init(reference)

        guard needDownload(of: request, for: unsafeReference) else {
            return
        }

        if let imageView = reference as? SmartImageView {
            Queue.isolatedMain.sync {
                imageView.setPlaceholder(placeholder)
            }
        }

        let unsafeAnimation = USendable(value: animation)
        let wrappedCompletion: ImageClosure = { result in
            let unsafeResult = USendable(value: result)
            let reference = unsafeReference.value
            Queue.isolatedMain.sync {
                unsafeResult.value.sourceURL = request.url
                if let imageView = reference as? SmartImageView {
                    unsafeAnimation.value.animate(imageView, image: unsafeResult.value.image)
                }
            }
            completion(result)
        }

        download(of: request, for: reference, completion: wrappedCompletion)
    }
}

// MARK: - Private

private func needDownload(of request: ImageRequest, for holder: USendable<ImageFetching.ImageReference>) -> Bool {
    return Queue.isolatedMain.sync {
        if let imageView = holder.value as? SmartImageView,
           let cachePolicy = request.cachePolicy,
           cachePolicy.canUseCachedData,
           let image = imageView.image,
           let currentSourceURL = image.sourceURL,
           currentSourceURL == request.url {
            return false
        }
        return true
    }
}

private extension ImageAnimation? {
    #if swift(>=6.0)
    @MainActor
    #endif
    func animate(_ imageView: SmartImageView, image: SmartImage?) {
        // ignore nil, to leave placeholder
        guard let image else {
            return
        }

        switch self {
        #if os(iOS) || os(tvOS)
        case .crossDissolve:
            if image.size == imageView.image?.size,
               let currentSourceURL = imageView.image?.sourceURL,
               image.sourceURL == currentSourceURL {
                return // No need to animate the same image, it's already here
            }

            UIView.transition(with: imageView,
                              duration: 0.24,
                              options: [.transitionCrossDissolve, .beginFromCurrentState],
                              animations: {
                                  imageView.image = image
                              })
        #endif

        case let .custom(animation):
            animation(imageView, image)

        case .none:
            imageView.image = image
        }
    }
}

private extension Result<SmartImage, Error> {
    var image: SmartImage? {
        switch self {
        case let .success(image):
            return image
        case .failure:
            return nil
        }
    }
}

private extension Result<SmartImage, Error> {
    var sourceURL: URL? {
        get {
            return image?.sourceURL
        }
        nonmutating set {
            image?.sourceURL = newValue
        }
    }
}
