import Foundation

public enum ImageAnimation {
    #if os(iOS) || os(tvOS)
    case crossDissolve
    #elseif os(macOS) || os(watchOS) || os(visionOS)
    // not supported yet
    #else
    #error("unsupported os")
    #endif

    case custom((_ imageView: ImageView, _ image: Image) -> Void)
}
