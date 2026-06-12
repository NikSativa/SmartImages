import Foundation
import SmartImages

public extension SmartImage {
    private enum AssociatedKeys {
        nonisolated(unsafe) static var sourceURL: StaticString = "Network.ImageFetcher.imageURL"
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
