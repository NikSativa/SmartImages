import Foundation
import NSpry

@testable import NImageDownloader

public final class FakeImageDownloaderTask: ImageDownloaderTask, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case start = "start()"
        case cancel = "cancel()"
    }

    public init() {}

    public func start() {
        return spryify()
    }

    public func cancel() {
        return spryify()
    }
}
