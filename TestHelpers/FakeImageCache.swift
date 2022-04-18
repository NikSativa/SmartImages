import Foundation
import NQueue
import NSpry

@testable import NImageDownloader

final class FakeImageCache: ImageCache, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case cached = "cached(for:)"
        case store = "store(_:for:)"
        case remove = "remove(for:)"
        case removeAll = "removeAll()"
    }

    init() {}

    func cached(for key: Key) -> Data? {
        return spryify(arguments: key)
    }

    func store(_ data: Data, for key: Key) {
        return spryify(arguments: data, key)
    }

    func remove(for key: Key) {
        return spryify(arguments: key)
    }

    func removeAll() {
        return spryify()
    }
}
