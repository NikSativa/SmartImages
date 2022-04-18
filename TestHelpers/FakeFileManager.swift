import Foundation
import NSpry

@testable import NImageDownloader

final class FakeFileManager: NImageDownloader.FileManager, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case urls = "urls(for:in:)"
    }

    func urls(for directory: NImageDownloader.FileManager.SearchPathDirectory,
              in domainMask: NImageDownloader.FileManager.SearchPathDomainMask) -> [URL] {
        return spryify(arguments: directory, domainMask)
    }
}

extension NImageDownloader.FileManager.SearchPathDirectory: SpryEquatable {}

extension NImageDownloader.FileManager.SearchPathDomainMask: SpryEquatable {}
