import Foundation

public protocol ImageDecoder {
    func decode(_ data: Data) -> Image?
}

// can be used as namespace for any ImageDecoder declared in any other place of app
public enum ImageDecoders {}

public extension ImageDecoders {
    struct Default: ImageDecoder {
        public init() {}

        public func decode(_ data: Data) -> Image? {
            return PlatformImage(data: data)?.sdk
        }
    }
}
