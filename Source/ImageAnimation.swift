import Foundation

/// Animation effects to apply when setting an image in an image view.
///
/// `ImageAnimation` provides built-in and custom animation options for smooth transitions
/// when images are loaded and displayed. Currently supports cross-dissolve effects on iOS/tvOS
/// and custom animation implementations for all platforms.
///
/// ## Usage Examples
/// ```swift
/// // Cross-dissolve animation (iOS/tvOS only)
/// let animation = ImageAnimation.crossDissolve
///
/// // Custom animation
/// let animation = ImageAnimation.custom { imageView, image in
///     imageView.alpha = 0.0
///     imageView.image = image
///     UIView.animate(withDuration: 0.3) {
///         imageView.alpha = 1.0
///     }
/// }
/// ```
public enum ImageAnimation {
    #if os(iOS) || os(tvOS)
    case crossDissolve
    #elseif os(macOS) || os(watchOS) || supportsVisionOS
    // not supported yet
    #else
    #error("unsupported os")
    #endif

    case custom((_ imageView: ImageView, _ image: Image) -> Void)
}

#if swift(>=6.0)
extension ImageAnimation: @unchecked Sendable {}
#endif
