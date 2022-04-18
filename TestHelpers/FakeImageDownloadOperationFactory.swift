import Foundation
import NCallback
import NSpry
import UIKit

@testable import NImageDownloader

final class FakeImageDownloadOperationFactory: ImageDownloadOperationFactory, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case make = "make(requestGenerator:completionCallback:url:)"
    }

    init() {}

    func make(requestGenerator: @escaping () -> Callback<UIImage?>,
              completionCallback: Callback<UIImage?>,
              url: URL) -> ImageDownloadOperation {
        return spryify(arguments: requestGenerator, completionCallback, url)
    }
}
