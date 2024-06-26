import Combine
import Foundation
import SmartImages
import SpryKit

public final class FakeImageDownloading: ImageDownloading, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case imageCache
        case downloadView = "download(of:for:animated:completion:)"
        case downloadInfo = "download(of:completion:)"
        case predownload = "predownload(of:completion:)"
        case cancel = "cancel(for:)"
    }

    public init() {}

    public var imageCache: ImageCaching? {
        return spryify()
    }

    public var completion: ImageClosure?
    public func download(of info: ImageInfo,
                         for imageView: ImageView,
                         animated animation: ImageAnimation?,
                         placeholder: ImagePlaceholder,
                         completion: @escaping ImageClosure) {
        self.completion = completion
        return spryify(arguments: info, imageView, animation, completion)
    }

    public func download(of info: ImageInfo,
                         completion: @escaping ImageClosure) -> AnyCancellable {
        self.completion = completion
        return spryify(arguments: info, completion)
    }

    public func predownload(of info: ImageInfo, completion: @escaping ImageClosure) {
        self.completion = completion
        return spryify(arguments: info, completion)
    }

    public func cancel(for imageView: ImageView) {
        return spryify(arguments: imageView)
    }
}
