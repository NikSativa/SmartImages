import Foundation
import SpryKit

@testable import FastImages

public final class FakeImageDownloaderFileManager: ImageDownloaderFileManager, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case urls = "urls(for:in:)"
    }

    public init() {}

    public func urls(for directory: FileManager.SearchPathDirectory,
                     in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        return spryify(arguments: directory, domainMask)
    }
}
