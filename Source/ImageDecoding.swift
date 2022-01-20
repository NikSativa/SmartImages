import Foundation
import NCallback
import UIKit

protocol ImageDecoding {
    func decode(_ data: Data) -> Callback<UIImage?>
}

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

extension Impl.ImageDecoding: ImageDecoding {
    func decode(_ data: Data) -> Callback<UIImage?> {
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
