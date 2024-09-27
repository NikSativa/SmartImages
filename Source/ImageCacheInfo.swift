import Foundation

/// The ImageCacheInfo is configuration for URLCache which implements the caching of responses to URL load requests
///
/// - Parameters:
///  - memoryCapacity: The memory capacity of the cache, in bytes. Default value is **40MB**
///  - diskCapacity: The disk capacity of the cache, in bytes. Default value is **400MB**
///  - directory: The path to an on-disk directory, where the system stores the on-disk cache. If directory is nil, the cache uses a default directory.
public struct ImageCacheInfo: Equatable {
    let directory: URL?
    let memoryCapacity: Int
    let diskCapacity: Int

    public init(directory: URL?,
                memoryCapacity: Int? = nil,
                diskCapacity: Int? = nil) {
        self.directory = directory
        self.memoryCapacity = memoryCapacity.recoverMemoryCapacity
        self.diskCapacity = diskCapacity.recoverDiskCapacity
    }

    public init(folderName: String = "DownloadedImages",
                fileManager: ImageDownloaderFileManager? = nil,
                memoryCapacity: Int? = nil,
                diskCapacity: Int? = nil) {
        self.directory = Self.directory(named: folderName, fileManager: fileManager)
        self.memoryCapacity = memoryCapacity.recoverMemoryCapacity
        self.diskCapacity = diskCapacity.recoverDiskCapacity
    }

    private static func directory(named: String,
                                  fileManager: ImageDownloaderFileManager? = nil) -> URL? {
        let fileManager = fileManager ?? FileManager.default
        let urls = fileManager.urls(for: .cachesDirectory,
                                    in: .userDomainMask)
        let directory = urls.first?.appendingPathComponent(named, isDirectory: true)
        return directory
    }
}

private extension Int? {
    var recoverMemoryCapacity: Int {
        if let self, self > 10 * 1024 * 1024 {
            return self
        }
        return 40 * 1024 * 1024 // 40MB
    }

    var recoverDiskCapacity: Int {
        if let self, self > 10 * 1024 * 1024 {
            return self
        }
        return 400 * 1024 * 1024 // 400MB
    }
}

#if swift(>=6.0)
extension ImageCacheInfo: Sendable {}
#endif
