import Foundation

public enum ImagePriority: Comparable {
    case veryLow
    case low
    case normal
    case high
    case veryHight

    public static let `default`: Self = .normal
    public static let prefetch: Self = .veryLow
}

#if swift(>=6.0)
extension ImagePriority: Sendable {}
#endif
