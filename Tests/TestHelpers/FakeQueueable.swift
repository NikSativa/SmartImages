#if canImport(SpryMacroAvailable) && swift(>=6.0)
import Foundation
import SpryKit
import Threading

@Spryable
final class FakeQueueable: Queueable {
    var shouldFireSyncClosures: Bool = false
    var asyncWorkItem: (() -> Void)?

    func async(execute workItem: @escaping () -> Void) {
        asyncWorkItem = workItem
        return spryify(arguments: workItem)
    }

    func asyncAfter(deadline: DispatchTime, flags: Queue.Flags, execute work: @escaping () -> Void) {
        asyncWorkItem = work
        return spryify(arguments: deadline, flags, work)
    }

    func asyncAfter(deadline: DispatchTime, execute work: @escaping () -> Void) {
        asyncWorkItem = work
        return spryify(arguments: deadline, work)
    }

    func sync(execute workItem: () -> Void) {
        if shouldFireSyncClosures {
            workItem()
        }

        return spryify()
    }

    func sync(execute workItem: () throws -> Void) rethrows {
        if shouldFireSyncClosures {
            try workItem()
        }

        return spryify()
    }

    func sync<T>(flags: Queue.Flags, execute work: () throws -> T) rethrows -> T {
        if shouldFireSyncClosures {
            return try spryify(arguments: flags, fallbackValue: work())
        }

        return spryify(arguments: flags)
    }

    func sync<T>(execute work: () throws -> T) rethrows -> T {
        if shouldFireSyncClosures {
            return try spryify(fallbackValue: work())
        }

        return spryify()
    }

    func sync<T>(flags: Queue.Flags, execute work: () -> T) -> T {
        if shouldFireSyncClosures {
            return spryify(arguments: flags, fallbackValue: work())
        }

        return spryify(arguments: flags)
    }

    func sync<T>(execute work: () -> T) -> T {
        if shouldFireSyncClosures {
            return spryify(fallbackValue: work())
        }

        return spryify()
    }
}

#if swift(>=6.0)
extension FakeQueueable: @unchecked Sendable {}
#endif

#endif
