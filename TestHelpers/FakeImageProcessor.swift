import Foundation
import NSpry

@testable import NImageDownloader

public final class FakeImageProcessor: ImageProcessor, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case process = "process(_:)"
    }

    public init() {}

    public func process(_ image: Image) -> Image {
        return spryify(arguments: image)
    }
}
