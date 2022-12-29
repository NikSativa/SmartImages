import Foundation
import NCallback

protocol ImageDecoding {
    func decode(_ data: Data) -> Callback<Image?>
}

// MARK: - Impl.ImageDecoding

extension Impl {
    struct ImageDecoding {
        private let decoders: [ImageDecoder]

        init(decoders: [ImageDecoder]) {
            if decoders.contains(where: { $0 is ImageDecoders.Default }) {
                self.decoders = decoders
            } else {
                self.decoders = decoders + [ImageDecoders.Default()]
            }
        }
    }
}

// MARK: - Impl.ImageDecoding + ImageDecoding

extension Impl.ImageDecoding: ImageDecoding {
    func decode(_ data: Data) -> Callback<Image?> {
        return .init { [decoders] actual in
            for decoder in decoders {
                if let image = decoder.decode(data) {
                    actual.complete(image)
                    return
                }
            }

            actual.complete(nil)
        }
    }
}
