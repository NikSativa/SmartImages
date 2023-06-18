import Foundation

internal extension URLRequest.CachePolicy {
    var canUseCachedData: Bool {
        switch self {
        case .returnCacheDataDontLoad,
             .returnCacheDataElseLoad,
             .useProtocolCachePolicy:
            return true
        case .reloadIgnoringLocalAndRemoteCacheData,
             .reloadIgnoringLocalCacheData,
             .reloadRevalidatingCacheData:
            return false
        @unknown default:
            return false
        }
    }
}
