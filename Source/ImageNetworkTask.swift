import Combine
import Foundation

// A cancellable network task returned by ``ImageNetworkProvider``.
//
// Call ``start()`` to begin the download and `cancel()` to abort it.
#if swift(>=6.0)
public protocol ImageNetworkTask: Cancellable, Sendable {
    func start()
}
#else
public protocol ImageNetworkTask: Cancellable {
    func start()
}
#endif
