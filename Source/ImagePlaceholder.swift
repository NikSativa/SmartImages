import Foundation

#if os(iOS) || os(tvOS) || supportsVisionOS || os(watchOS)
import UIKit
#elseif os(macOS)
import Cocoa
#else
#error("unsupported os")
#endif

public enum ImagePlaceholder {
    #if swift(>=6.0)
    public typealias CustomAnimation = @MainActor (ImageView) -> Void
    #else
    public typealias CustomAnimation = (ImageView) -> Void
    #endif

    case none
    case clear
    case image(Image)
    case custom(CustomAnimation)

    #if os(iOS) || os(tvOS) || os(watchOS) || supportsVisionOS
    case imageNamed(String, bundle: Bundle)

    func imageNamed(_ name: String) -> Self {
        return .imageNamed(name, bundle: .main)
    }

    #elseif os(macOS)
    case imageNamed(String)
    #endif

    #if swift(>=5.9) && (os(iOS) || os(tvOS) || supportsVisionOS)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
    func resource(_ res: ImageResource) -> Self {
        return .init(resource: res)
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
    public init(resource res: ImageResource) {
        self = .custom { view in
            view.image = Image(resource: res)
        }
    }
    #endif

    public init(_ image: Image?) {
        self = image.map(Self.image) ?? .clear
    }
}

#if swift(>=6.0)
extension ImagePlaceholder: @unchecked Sendable {}
#endif
