import Foundation

/// only for internal usage
internal extension Image {
    private enum AssociatedKeys {
        static var sourceURL: StaticString = "Network.ImageDownloader.imageURL"
    }

    @objc var sourceURL: URL? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.sourceURL) as? URL
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.sourceURL, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
