import Foundation
import Threading

#if swift(>=6.0)
public protocol ImageCaching: Sendable {
    func cached(for key: URL) -> Data?
    func store(_ data: Data, for key: URL)
    func remove(for key: URL)
    func removeAll()
}
#else
public protocol ImageCaching {
    func cached(for key: URL) -> Data?
    func store(_ data: Data, for key: URL)
    func remove(for key: URL)
    func removeAll()
}
#endif

internal final class ImageCache {
    private let mutex: Mutexing = Mutex.pthread(.recursive)
    internal let urlCache: URLCache

    init(info: ImageCacheInfo = .init()) {
        self.urlCache = URLCache(memoryCapacity: info.memoryCapacity,
                                 diskCapacity: info.diskCapacity,
                                 directory: info.directory)
    }
}

// MARK: - ImageCaching

extension ImageCache: ImageCaching {
    func cached(for key: URL) -> Data? {
        return mutex.sync {
            return urlCache.cachedResponse(for: key.request)?.data
        }
    }

    func store(_ data: Data, for key: URL) {
        return mutex.sync {
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
        return mutex.sync {
            urlCache.removeCachedResponse(for: key.request)
        }
    }

    func removeAll() {
        return mutex.sync {
            urlCache.removeAllCachedResponses()
        }
    }
}

private extension URL {
    var request: URLRequest {
        return .init(url: self)
    }
}
