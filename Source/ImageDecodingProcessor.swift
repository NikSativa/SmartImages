import Foundation

internal struct ImageDecodingProcessor {
    private let decoders: [ImageDecoding]

    init(decoders: [ImageDecoding]) {
        if decoders.contains(where: { $0 is ImageDecoders.Default }) {
            self.decoders = decoders
        } else {
            self.decoders = decoders + [ImageDecoders.Default()]
        }
    }

    func decode(_ data: Data) -> Image? {
        for decoder in decoders {
            if let image = decoder.decode(data) {
                return image
            }
        }
        return nil
    }
}
