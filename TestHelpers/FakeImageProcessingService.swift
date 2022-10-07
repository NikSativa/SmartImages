import Foundation
import NCallback
import NSpry

@testable import NImageDownloader

final class FakeImageProcessing: ImageProcessing, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case process = "process(_:processors:)"
    }

    init() {}

    func process(_ image: Image, processors: [ImageProcessor]) -> Callback<Image> {
        return spryify(arguments: image, processors)
    }
}
