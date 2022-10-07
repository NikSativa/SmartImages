import Foundation

// only for internal usage
extension Image {
    private enum AssociatedKeys {
        static var sourceURL = "Network.ImageDownloader.imageURL"
    }

    @objc internal var sourceURL: URL? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.sourceURL) as? URL
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.sourceURL, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
