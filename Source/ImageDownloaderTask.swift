import Combine
import Foundation

public protocol ImageDownloaderTask: Cancellable {
    func start()
}
