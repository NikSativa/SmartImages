import Foundation
import SmartImages
import SpryKit

final class FakeImageCaching: ImageCaching, Spryable {
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

    func cached(for key: URL) -> Data? {
        return spryify(arguments: key)
    }

    func store(_ data: Data, for key: URL) {
        return spryify(arguments: data, key)
    }

    func remove(for key: URL) {
        return spryify(arguments: key)
    }

    func removeAll() {
        return spryify()
    }
}
