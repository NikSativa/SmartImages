import Foundation
import UIKit

public protocol ImageDecoder {
    func decode(_ data: Data) -> UIImage?
}

// can be used as namespace for any ImageDecoder declared in any other place of app
public enum ImageDecoders {}

public extension ImageDecoders {
    struct Default: ImageDecoder {
        public init() {}

        public func decode(_ data: Data) -> UIImage? {
            return UIImage(data: data)
        }
    }
}
