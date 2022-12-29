import Foundation
import NQueue
import NRequest

protocol ImageCache {
    typealias Key = URL

    func cached(for key: Key) -> Data?
    func store(_ data: Data, for key: Key)
    func remove(for key: Key)
    func removeAll()
}

extension ImageCache {
    subscript(_ key: Key) -> Data? {
        return cached(for: key)
    }
}

// MARK: - Impl.ImageCache

extension Impl {
    final class ImageCache {
        private let mutex: Mutexing = Mutex.pthread(.recursive)
        internal let urlCache: URLCache

        init(fileManager: NImageDownloader.FileManager) {
            let folderName = "Images"
            if #available(iOS 13, macOS 10.15, *) {
                let urls = fileManager.urls(for: .cachesDirectory,
                                            in: .userDomainMask)
                let directory = urls.first?.appendingPathComponent(folderName, isDirectory: true)

                urlCache = URLCache(memoryCapacity: 40 * 1024 * 1024,
                                    diskCapacity: 400 * 1024 * 1024,
                                    directory: directory)
            } else {
                self.urlCache = URLCache(memoryCapacity: 40 * 1024 * 1024,
                                         diskCapacity: 400 * 1024 * 1024,
                                         diskPath: folderName)
            }
        }
    }
}

// MARK: - Impl.ImageCache + ImageCache

extension Impl.ImageCache: ImageCache {
    func cached(for key: Key) -> Data? {
        return mutex.sync {
            return urlCache.cachedResponse(for: key.did)?.data
        }
    }

    func store(_ data: Data, for key: Key) {
        return mutex.sync {
            let response = CachedURLResponse(response: .init(url: key,
                                                             mimeType: nil,
                                                             expectedContentLength: 0,
                                                             textEncodingName: nil),
                                             data: data,
                                             userInfo: nil,
                                             storagePolicy: .allowed)
            urlCache.storeCachedResponse(response, for: key.did)
        }
    }

    func remove(for key: Key) {
        return mutex.sync {
            urlCache.removeCachedResponse(for: key.did)
        }
    }

    func removeAll() {
        return mutex.sync {
            urlCache.removeAllCachedResponses()
        }
    }
}

private extension URL {
    var did: URLRequest {
        return .init(url: self)
    }
}
