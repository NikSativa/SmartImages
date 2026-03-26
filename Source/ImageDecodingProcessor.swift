import Foundation

/// Decodes raw `Data` into a `SmartImage` using a chain of decoders.
///
/// Iterates through the provided decoders in order until one successfully decodes the data.
/// If none of the custom decoders can handle the data, `ImageDecoders.Default` is used as a fallback.
public struct ImageDecodingProcessor {
    private let decoders: [ImageDecoding]

    public init(decoders: [ImageDecoding]) {
        if decoders.contains(where: { $0 is ImageDecoders.Default }) {
            self.decoders = decoders
        } else {
            self.decoders = decoders + [ImageDecoders.Default()]
        }
    }

    public func decode(_ data: Data) -> SmartImage? {
        for decoder in decoders {
            if let image = decoder.decode(data) {
                return image
            }
        }
        return nil
    }
}

#if swift(>=6.0)
extension ImageDecodingProcessor: Sendable {}
#endif
