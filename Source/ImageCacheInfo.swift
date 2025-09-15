import Foundation

/// Configuration for image caching behavior using URLCache.
///
/// `ImageCacheInfo` defines how downloaded images are cached in memory and on disk,
/// providing control over cache size, storage location, and cleanup behavior.
///
/// ## Default Values
/// - **Memory Cache**: 40MB (minimum 10MB)
/// - **Disk Cache**: 400MB (minimum 10MB)
/// - **Storage Location**: System cache directory
///
/// ## Usage Examples
/// ```swift
/// // Default configuration
/// let cache = ImageCacheInfo(folderName: "MyAppImages")
///
/// // Custom sizes
/// let cache = ImageCacheInfo(
///     directory: customDirectory,
///     memoryCapacity: 80 * 1024 * 1024,  // 80MB
///     diskCapacity: 800 * 1024 * 1024     // 800MB
/// )
/// ```
public struct ImageCacheInfo: Equatable {
    public let directory: URL
    public let memoryCapacity: Int
    public let diskCapacity: Int

    /// Creates a cache configuration with a specific directory and capacity settings.
    ///
    /// - Parameters:
    ///   - directory: The directory URL where cached images will be stored.
    ///   - memoryCapacity: Memory cache size in bytes. Defaults to 40MB, minimum 10MB.
    ///   - diskCapacity: Disk cache size in bytes. Defaults to 400MB, minimum 10MB.
    public init(directory: URL,
                memoryCapacity: Int? = nil,
                diskCapacity: Int? = nil) {
        self.directory = directory
        self.memoryCapacity = memoryCapacity.recoverMemoryCapacity
        self.diskCapacity = diskCapacity.recoverDiskCapacity
    }

    /// Creates a cache configuration using a folder name in the system cache directory.
    ///
    /// - Parameters:
    ///   - named: The name of the folder for cache storage. Defaults to "DownloadedImages".
    ///   - searchPathDirectory: The search path directory for cache storage. Defaults to `.cachesDirectory`.
    ///   - searchPathDomainMask: The search path domain mask. Defaults to `.userDomainMask`.
    ///   - memoryCapacity: Memory cache size in bytes. Defaults to 40MB, minimum 10MB.
    ///   - diskCapacity: Disk cache size in bytes. Defaults to 400MB, minimum 10MB.
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
