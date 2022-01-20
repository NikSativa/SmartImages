import Foundation
import NCallback
import NSpry
import UIKit

@testable import NImageDownloader

final class FakeImageProcessing: ImageProcessing, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case process = "process(_:processors:)"
    }

    init() {
    }

    func process(_ image: UIImage, processors: [ImageProcessor]) -> Callback<UIImage> {
        return spryify(arguments: image, processors)
    }
}
