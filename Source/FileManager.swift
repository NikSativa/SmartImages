import Foundation

protocol FileManager {
    typealias SearchPathDirectory = Foundation.FileManager.SearchPathDirectory
    typealias SearchPathDomainMask = Foundation.FileManager.SearchPathDomainMask

    func urls(for directory: SearchPathDirectory, in domainMask: SearchPathDomainMask) -> [URL]
}

// MARK: - Impl.FileManager

extension Impl {
    final class FileManager {
        private let fileManager: Foundation.FileManager

        init(fileManager: Foundation.FileManager = .default) {
            self.fileManager = fileManager
        }
    }
}

// MARK: - Impl.FileManager + FileManager

extension Impl.FileManager: FileManager {
    func urls(for directory: SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        return fileManager.urls(for: directory, in: domainMask)
    }
}
