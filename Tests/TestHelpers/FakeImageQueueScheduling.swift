import Foundation
import SpryKit
@testable import SmartImages

final class FakeImageQueueScheduling: ImageQueueScheduling, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case add = "add(hash:prioritizer:starter:)"
    }

    init() {}

    typealias StarterClosure = (_ completion: @escaping VoidClosure) -> Void

    var prioritizer: (() -> FetchQueueingPriority)?
    var starter: StarterClosure?
    func add(hash: AnyHashable,
             prioritizer: @escaping () -> FetchQueueingPriority,
             starter: @escaping (_ completion: @escaping VoidClosure) -> Void) {
        self.prioritizer = prioritizer
        self.starter = starter
        return spryify(arguments: hash, prioritizer, starter)
    }
}

#if swift(>=6.0)
extension FakeImageQueueScheduling: @unchecked Sendable {}
#endif
