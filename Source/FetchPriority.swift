import Foundation

/// Represents the priority level for image download tasks.
///
/// `FetchPriority` determines the order in which images are downloaded. Higher priority images
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
/// > Note: The previously available `veryHight` case has been deprecated in favor of `veryHigh`.
///
/// ## Usage Example
/// ```swift
/// let info = ImageRequest(
///     url: imageURL,
///     priority: .high  // This image will be downloaded before lower priority images
/// )
/// ```
public enum FetchPriority: Comparable {
    case veryLow
    case low
    case normal
    case high
    case veryHigh

    @available(*, deprecated, renamed: "veryHigh")
    public static let veryHight: Self = .veryHigh

    public static let `default`: Self = .normal
    public static let prefetch: Self = .veryLow
}

#if swift(>=6.0)
extension FetchPriority: Sendable {}
#endif
