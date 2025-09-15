import Foundation

/// Represents the priority level for image download tasks.
///
/// `ImagePriority` determines the order in which images are downloaded. Higher priority images
/// are processed before lower priority ones, with visible image views always taking precedence
/// over background downloads regardless of priority level.
///
/// ## Priority Levels
/// - `.veryLow` - Background prefetching and low-importance images
/// - `.low` - Secondary content images
/// - `.normal` - Standard priority (default)
/// - `.high` - Important UI elements
/// - `.veryHigh` - Critical UI elements that should load immediately
///
/// ## Usage Example
/// ```swift
/// let info = ImageInfo(
///     url: imageURL,
///     priority: .high  // This image will be downloaded before lower priority images
/// )
/// ```
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
