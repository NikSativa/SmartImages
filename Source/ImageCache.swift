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
/// A protocol for caching image data associated with URLs.
///
/// Conform to this protocol to implement custom image caching mechanisms.
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

public final class ImageCache: @unchecked Sendable {
    private static let createdAtKey = "SmartImages.createdAt"

    @AtomicValue
    public private(set) var urlCache: URLCache

    private let ttl: TimeInterval?

    public init(configuration: ImageCacheConfiguration) {
        self.urlCache = URLCache(memoryCapacity: configuration.memoryCapacity,
                                 diskCapacity: configuration.diskCapacity,
                                 directory: configuration.directory)
        self.ttl = configuration.ttl
    }

    private func isExpired(_ response: CachedURLResponse) -> Bool {
        guard let ttl else {
            return false
        }

        guard let createdAt = response.userInfo?[Self.createdAtKey] as? TimeInterval else {
            // Entries written before TTL was configured: treat as fresh and let LRU evict.
            return false
        }

        return Date().timeIntervalSince1970 - createdAt > ttl
    }
}

// MARK: - ImageCaching

extension ImageCache: ImageCaching {
    public func cached(for key: URL) -> Data? {
        return $urlCache.sync { urlCache in
            guard let response = urlCache.cachedResponse(for: key.request) else {
                return nil
            }

            if isExpired(response) {
                urlCache.removeCachedResponse(for: key.request)
                return nil
            }
            return response.data
        }
    }

    public func store(_ data: Data, for key: URL) {
        return $urlCache.sync { urlCache in
            let userInfo: [AnyHashable: Any]? = ttl.map { _ in
                [Self.createdAtKey: Date().timeIntervalSince1970]
            }
            let response = CachedURLResponse(response: .init(url: key,
                                                             mimeType: nil,
                                                             expectedContentLength: 0,
                                                             textEncodingName: nil),
                                             data: data,
                                             userInfo: userInfo,
                                             storagePolicy: .allowed)
            urlCache.storeCachedResponse(response, for: key.request)
        }
    }

    public func remove(for key: URL) {
        return $urlCache.sync { urlCache in
            urlCache.removeCachedResponse(for: key.request)
        }
    }

    public func removeAll() {
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
