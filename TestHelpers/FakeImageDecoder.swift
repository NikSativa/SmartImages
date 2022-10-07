import Foundation
import NSpry

@testable import NImageDownloader

final class FakeImageDecoder: ImageDecoder, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case decode = "decode(_:)"
    }

    init() {}

    func decode(_ data: Data) -> Image? {
        return spryify(arguments: data)
    }
}
