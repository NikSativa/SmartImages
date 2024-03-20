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
    @discardableResult
    func setPlaceholder(_ placeholder: Image? = nil) -> Self {
        Queue.main.sync {
            self.image = placeholder
        }
        return self
    }
}
