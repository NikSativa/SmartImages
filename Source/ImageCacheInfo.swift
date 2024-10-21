import Foundation

/// The ImageCacheInfo is configuration for URLCache which implements the caching of responses to URL load requests
///
/// - Parameters:
///  - memoryCapacity: The memory capacity of the cache, in bytes. Default value is **40MB**. Minimum value is **10MB**
///  - diskCapacity: The disk capacity of the cache, in bytes. Default value is **400MB**. Minimum value is **10MB**
///  - directory: The path to an on-disk directory, where the system stores the on-disk cache. If directory is nil, the cache uses a default directory.
public struct ImageCacheInfo: Equatable {
    public let directory: URL
    public let memoryCapacity: Int
    public let diskCapacity: Int

    /// Configuration for URLCache used for caching responses to URL load requests.
    ///
    /// - Parameters:
    ///    - directory: The directory URL for the cache.
    ///    - memoryCapacity: The memory capacity of the cache in bytes. Default value is 40MB.
    ///    - diskCapacity: The disk capacity of the cache in bytes.
    public init(directory: URL,
                memoryCapacity: Int? = nil,
                diskCapacity: Int? = nil) {
        self.directory = directory
        self.memoryCapacity = memoryCapacity.recoverMemoryCapacity
        self.diskCapacity = diskCapacity.recoverDiskCapacity
    }

    /// Configuration for URLCache used for caching responses to URL load requests.
    /// - Parameters:
    ///   - folderName: The name of the folder where the cache is stored.
    ///   - searchPathDirectory: The search path directory. Default value is **.cachesDirectory**
    ///   - searchPathDomainMask: The search path domain mask. Default value is **.userDomainMask**
    ///   - memoryCapacity: The memory capacity of the cache, in bytes. Default value is **40MB**. Minimum value is **10MB**
    ///   - diskCapacity: The disk capacity of the cache, in bytes. Default value is **400MB**. Minimum value is **10MB**
    public init?(folderName named: String = "DownloadedImages",
                 searchPathDirectory: FileManager.SearchPathDirectory = .cachesDirectory,
                 searchPathDomainMask: FileManager.SearchPathDomainMask = .userDomainMask,
                 memoryCapacity: Int? = nil,
                 diskCapacity: Int? = nil) {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: searchPathDirectory,
                                    in: searchPathDomainMask)
        let directory = urls.first?.appendingPathComponent(named, isDirectory: true)
        guard let directory else {
            return nil
        }

        self.directory = directory
        self.memoryCapacity = memoryCapacity.recoverMemoryCapacity
        self.diskCapacity = diskCapacity.recoverDiskCapacity
    }
}

private extension Int? {
    var recoverMemoryCapacity: Int {
        guard let self else {
            return 40 * 1024 * 1024 // 40MB
        }

        return max(self, 10 * 1024 * 1024) // 10MB
    }

    var recoverDiskCapacity: Int {
        guard let self else {
            return 400 * 1024 * 1024 // 400MB
        }

        return max(self, 10 * 1024 * 1024) // 10MB
    }
}

#if swift(>=6.0)
extension ImageCacheInfo: Sendable {}
#endif
