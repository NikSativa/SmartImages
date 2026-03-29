#if canImport(SwiftUI)
import SwiftUI

public enum SmartImagePhase {
    case idle
    case loading
    case loaded(SwiftUI.Image)
    case failed
    case noURL

    internal var shouldFetch: Bool {
        switch self {
        case .idle:
            return true
        case .loading,
             .loaded,
             .failed,
             .noURL:
            return false
        }
    }
}
#endif
