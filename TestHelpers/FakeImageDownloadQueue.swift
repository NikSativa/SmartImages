import Foundation
import NCallback
import NSpry
import UIKit

@testable import NImageDownloader

final class FakeImageDownloadQueue: ImageDownloadQueue, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case add = "add(requestGenerator:completionCallback:url:prioritizer:)"
        case cancel = "cancel(for:)"
    }

    init() {}

    func add(requestGenerator: @autoclosure @escaping () -> Callback<UIImage?>,
             completionCallback: Callback<UIImage?>,
             url: URL,
             prioritizer: @escaping (URL) -> Priority) {
        return spryify(arguments: requestGenerator, completionCallback, url, prioritizer)
    }

    func cancel(for url: URL) {
        return spryify(arguments: url)
    }
}
