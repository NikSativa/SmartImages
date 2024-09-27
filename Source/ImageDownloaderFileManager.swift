import Foundation

#if swift(>=6.0)
/// a long name just to avoid confusion with the real name
/// - Note: only uses the **first** URL
public protocol ImageDownloaderFileManager: Sendable {
    func urls(for directory: FileManager.SearchPathDirectory,
              in domainMask: FileManager.SearchPathDomainMask) -> [URL]
}

extension Foundation.FileManager: @unchecked @retroactive Sendable {}
#else
/// a long name just to avoid confusion with the real name
/// - Note: only uses the **first** URL
public protocol ImageDownloaderFileManager {
    func urls(for directory: FileManager.SearchPathDirectory,
              in domainMask: FileManager.SearchPathDomainMask) -> [URL]
}
#endif

extension FileManager: ImageDownloaderFileManager {}
