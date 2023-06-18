import Foundation

/// a long name just to avoid confusion with the real name
/// - Note: only uses the **first** URL
public protocol ImageDownloaderFileManager {
    func urls(for directory: FileManager.SearchPathDirectory,
              in domainMask: FileManager.SearchPathDomainMask) -> [URL]
}

extension FileManager: ImageDownloaderFileManager {}
