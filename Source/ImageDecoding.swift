import Foundation

#if swift(>=6.0)
/// Protocol to decode an image from a Data object
public protocol ImageDecoding: Sendable {
    func decode(_ data: Data) -> Image?
}
#else
/// Protocol to decode an image from a Data object
public protocol ImageDecoding {
    func decode(_ data: Data) -> Image?
}
#endif

/// Namespace for any ImageDecoder declared in any other place of app
public enum ImageDecoders {}

// MARK: - ImageDecoders.Default

public extension ImageDecoders {
    /// Default `ImageDecoding` implementation
    struct Default: ImageDecoding {
        public init() {}

        public func decode(_ data: Data) -> Image? {
            return PlatformImage(data: data)?.sdk
        }
    }
}
