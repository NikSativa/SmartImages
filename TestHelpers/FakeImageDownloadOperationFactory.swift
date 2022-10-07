import Foundation
import NCallback
import NSpry

@testable import NImageDownloader

final class FakeImageDownloadOperationFactory: ImageDownloadOperationFactory, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case make = "make(requestGenerator:completionCallback:url:)"
    }

    init() {}

    func make(requestGenerator: @escaping () -> Callback<Image?>,
              completionCallback: Callback<Image?>,
              url: URL) -> ImageDownloadOperation {
        return spryify(arguments: requestGenerator, completionCallback, url)
    }
}
