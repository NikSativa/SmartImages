import Foundation
import NSpry

@testable import NImageDownloader

public final class FakeImageDecoder: ImageDecoding, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case decode = "decode(_:)"
    }

    public init() {}

    public func decode(_ data: Data) -> Image? {
        return spryify(arguments: data)
    }
}
