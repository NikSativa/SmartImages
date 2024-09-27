import Foundation

#if swift(>=6.0)
public protocol ImageDecoding: Sendable {
    func decode(_ data: Data) -> Image?
}
#else
public protocol ImageDecoding {
    func decode(_ data: Data) -> Image?
}
#endif

/// Namespace for any ImageDecoder declared in any other place of app
public enum ImageDecoders {}

// MARK: - ImageDecoders.Default

public extension ImageDecoders {
    struct Default: ImageDecoding {
        public init() {}

        public func decode(_ data: Data) -> Image? {
            return PlatformImage(data: data)?.sdk
        }
    }
}
