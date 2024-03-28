import Foundation

import Foundation
import NQueue

#if os(iOS) || os(tvOS) || os(visionOS) || os(watchOS)
import UIKit
#elseif os(macOS)
import Cocoa
#else
#error("unsupported os")
#endif

public extension ImageView {
    func setPlaceholder(_ placeholder: ImagePlaceholder) {
        Queue.main.sync {
            switch placeholder {
            case .image(let image):
                self.image = image
            case .clear:
                self.image = nil
            case .custom(let closure):
                closure(self)
            case .none:
                break

            #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
            case .imageNamed(let name, let bundle):
                self.image = Image(named: name, in: bundle, with: nil)
            #elseif os(macOS)
            case .imageNamed(let name):
                self.image = Image(named: name)
            #endif
            }
        }
    }
}
