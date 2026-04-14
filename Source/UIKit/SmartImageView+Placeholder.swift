import Foundation
import SmartImages
import Threading

#if os(iOS) || os(tvOS) || supportsVisionOS || os(watchOS)
import UIKit
#elseif os(macOS)
import Cocoa
#else
#error("unsupported os")
#endif

public extension SmartImageView {
    // Sets the placeholder content for the image view.
    //
    // This method applies the specified placeholder to the image view, which is typically
    // called before starting an image download to show loading state or fallback content.
    //
    // - Parameter placeholder: The placeholder to display in the image view.
    #if swift(>=6.0)
    @MainActor
    #endif
    func setPlaceholder(_ placeholder: ImagePlaceholder) {
        switch placeholder {
        case let .image(image):
            self.image = image
        case .clear:
            image = nil
        case let .custom(closure):
            closure(self)
        case .none:
            break
        #if os(iOS) || os(tvOS) || os(watchOS) || supportsVisionOS
        case let .imageNamed(name, bundle):
            image = SmartImage(named: name, in: bundle, with: nil)
        #elseif os(macOS)
        case let .imageNamed(name):
            image = SmartImage(named: name)
        #endif
        }
    }
}
