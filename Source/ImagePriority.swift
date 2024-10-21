import Foundation

/// Represents the priority of an image download task.
/// The priority is used to determine the order in which the images are downloaded, but higher priority images with image view are downloaded first.
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
