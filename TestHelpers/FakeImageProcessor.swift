import Foundation
import NSpry

@testable import NImageDownloader

final class FakeImageProcessor: ImageProcessor, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case process = "process(_:)"
    }

    init() {}

    func process(_ image: Image) -> Image {
        return spryify(arguments: image)
    }
}
