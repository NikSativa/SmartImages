import Foundation
import Threading

#if swift(>=6.0)
/// A protocol for caching image data associated with URLs.
///
/// Conform to this protocol to implement custom image caching mechanisms.
public protocol ImageCaching: Sendable {
    /// Retrieves cached image data for a given URL key.
    ///
    /// - Parameter key: The URL key for the cached image data.
    /// - Returns: The cached image data if available, otherwise nil.
    func cached(for key: URL) -> Data?
    /// Stores image data in the cache for a specified URL key.
    ///
    /// - Parameters:
    ///   - data: The image data to store in the cache.
    ///   - key: The URL key associated with the image data.
    func store(_ data: Data, for key: URL)
    /// Removes cached image data for a specific URL key.
    ///
    /// - Parameter key: The URL key for the cached image data to remove.
    func remove(for key: URL)
    /// Clears all cached image data from the cache.
    func removeAll()
}
#else
public protocol ImageCaching {
    /// Retrieves cached image data for a given URL key.
    ///
    /// - Parameter key: The URL key for the cached image data.
    /// - Returns: The cached image data if available, otherwise nil.
    func cached(for key: URL) -> Data?
    /// Stores image data in the cache for a specified URL key.
    ///
    /// - Parameters:
    ///   - data: The image data to store in the cache.
    ///   - key: The URL key associated with the image data.
    func store(_ data: Data, for key: URL)
    /// Removes cached image data for a specific URL key.
    ///
    /// - Parameter key: The URL key for the cached image data to remove.
    func remove(for key: URL)
    /// Clears all cached image data from the cache.
    func removeAll()
}
#endif

internal final class ImageCache: @unchecked Sendable {
    @AtomicValue
    internal private(set) var urlCache: URLCache

    init(info: ImageCacheInfo) {
        self.urlCache = URLCache(memoryCapacity: info.memoryCapacity,
                                 diskCapacity: info.diskCapacity,
                                 directory: info.directory)
    }
}

// MARK: - ImageCaching

extension ImageCache: ImageCaching {
    func cached(for key: URL) -> Data? {
        return $urlCache.sync { urlCache in
            return urlCache.cachedResponse(for: key.request)?.data
        }
    }

    func store(_ data: Data, for key: URL) {
        return $urlCache.sync { urlCache in
            let response = CachedURLResponse(response: .init(url: key,
                                                             mimeType: nil,
                                                             expectedContentLength: 0,
                                                             textEncodingName: nil),
                                             data: data,
                                             userInfo: nil,
                                             storagePolicy: .allowed)
            urlCache.storeCachedResponse(response, for: key.request)
        }
    }

    func remove(for key: URL) {
        return $urlCache.sync { urlCache in
            urlCache.removeCachedResponse(for: key.request)
        }
    }

    func removeAll() {
        return $urlCache.sync { urlCache in
            urlCache.removeAllCachedResponses()
        }
    }
}

private extension URL {
    var request: URLRequest {
        return .init(url: self)
    }
}
