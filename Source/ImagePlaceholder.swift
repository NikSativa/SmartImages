import Foundation

#if os(iOS) || os(tvOS) || supportsVisionOS || os(watchOS)
import UIKit
#elseif os(macOS)
import Cocoa
#else
#error("unsupported os")
#endif

/// Represents the placeholder content to display in an image view while loading or when loading fails.
///
/// `ImagePlaceholder` provides various options for showing placeholder content during image loading,
/// including static images, named images, custom implementations, or no placeholder at all.
///
/// ## Usage Examples
/// ```swift
/// // Use a static image
/// let placeholder = ImagePlaceholder.image(UIImage(systemName: "photo")!)
///
/// // Use a named image from bundle
/// let placeholder = ImagePlaceholder.imageNamed("placeholder")
///
/// // Clear the current image
/// let placeholder = ImagePlaceholder.clear
///
/// // Custom placeholder implementation
/// let placeholder = ImagePlaceholder.custom { imageView in
///     imageView.backgroundColor = .gray
///     imageView.contentMode = .center
/// }
/// ```
public enum ImagePlaceholder {
    #if swift(>=6.0)
    public typealias CustomSetter = @MainActor (ImageView) -> Void
    public nonisolated(unsafe) static var `default`: Self = .none
    #else
    public typealias CustomSetter = (ImageView) -> Void
    public static var `default`: Self = .none
    #endif

    /// A placeholder that does nothing.
    case none
    /// Clears the image view
    case clear
    /// A placeholder that shows an image which will be replaced by the downloaded image.
    case image(Image)
    /// Custom placeholder that allows you to set the image view with your own implementation
    case custom(CustomSetter)

    #if os(iOS) || os(tvOS) || os(watchOS) || supportsVisionOS
    /// A placeholder that shows an image which will be replaced by the downloaded image.
    case imageNamed(String, bundle: Bundle)

    /// A placeholder that shows an image which will be replaced by the downloaded image.
    func imageNamed(_ name: String) -> Self {
        return .imageNamed(name, bundle: .main)
    }

    #elseif os(macOS)
    /// A placeholder that shows an image which will be replaced by the downloaded image.
    case imageNamed(String)
    #endif

    #if swift(>=5.9) && (os(iOS) || os(tvOS) || supportsVisionOS)
    /// A placeholder that shows an image which will be replaced by the downloaded image.
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
    func resource(_ res: ImageResource) -> Self {
        return .init(resource: res)
    }

    /// A placeholder that shows an image which will be replaced by the downloaded image.
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
    public init(resource res: ImageResource) {
        self = .custom { view in
            view.image = Image(resource: res)
        }
    }
    #endif

    /// A placeholder that shows an image which will be replaced by the downloaded image.
    public init(_ image: Image?) {
        self = image.map(Self.image) ?? .clear
    }
}

#if swift(>=6.0)
extension ImagePlaceholder: @unchecked Sendable {}
#endif
