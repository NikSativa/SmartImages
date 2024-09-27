import Combine
import Foundation

#if swift(>=6.0)
public protocol ImageDownloaderTask: Cancellable, Sendable {
    func start()
}
#else
public protocol ImageDownloaderTask: Cancellable {
    func start()
}
#endif
