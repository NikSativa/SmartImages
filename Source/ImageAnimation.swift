import Foundation

public enum ImageAnimation {
    #if os(iOS) || os(tvOS) || os(watchOS)
    case crossDissolve
    #elseif os(macOS)
    // not supported yet
    #else
    #error("unsupported os")
    #endif

    case custom((_ imageView: ImageView, _ image: Image) -> Void)
}
