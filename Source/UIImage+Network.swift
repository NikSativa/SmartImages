import Foundation

/// only for internal usage
internal extension Image {
    private enum AssociatedKeys {
        #if swift(>=6.0)
        nonisolated(unsafe) static var sourceURL: StaticString = "Network.ImageDownloader.imageURL"
        #else
        static var sourceURL: StaticString = "Network.ImageDownloader.imageURL"
        #endif
    }

    @objc
    var sourceURL: URL? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.sourceURL) as? URL
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.sourceURL, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
