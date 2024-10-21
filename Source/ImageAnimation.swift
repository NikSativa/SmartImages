import Foundation

/// Animation to be used when setting an image to an image view.
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
