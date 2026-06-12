import Combine
import Foundation

// A cancellable network task returned by ``ImageNetworkProvider``.
//
// Call ``start()`` to begin the download and `cancel()` to abort it.
public protocol ImageNetworkTask: Cancellable, Sendable {
    func start()
}
