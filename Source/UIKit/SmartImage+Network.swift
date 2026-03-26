import Foundation
import SmartImages

public extension SmartImage {
    private enum AssociatedKeys {
        #if swift(>=6.0)
        nonisolated(unsafe) static var sourceURL: StaticString = "Network.ImageFetcher.imageURL"
        #else
        static var sourceURL: StaticString = "Network.ImageFetcher.imageURL"
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
