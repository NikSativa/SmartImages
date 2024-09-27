import Foundation

import Foundation
import Threading

#if os(iOS) || os(tvOS) || supportsVisionOS || os(watchOS)
import UIKit
#elseif os(macOS)
import Cocoa
#else
#error("unsupported os")
#endif

public extension ImageView {
    #if swift(>=6.0)
    @MainActor
    #endif
    func setPlaceholder(_ placeholder: ImagePlaceholder) {
        switch placeholder {
        case .image(let image):
            self.image = image
        case .clear:
            image = nil
        case .custom(let closure):
            closure(self)
        case .none:
            break

        #if os(iOS) || os(tvOS) || os(watchOS) || supportsVisionOS
        case .imageNamed(let name, let bundle):
            image = Image(named: name, in: bundle, with: nil)
        #elseif os(macOS)
        case .imageNamed(let name):
            image = Image(named: name)
        #endif
        }
    }
}
