import Foundation
import Threading

#if canImport(SwiftUI)
import SwiftUI

/// A reference holder for SwiftUI environments where image downloads need to be managed.
///
/// `ImageDownloadReference` provides a way to maintain download task lifecycle in SwiftUI contexts
/// where traditional view references might not be available.
public final class ImageDownloadReference {
    /// Creates a new image download reference instance.
    public init() {}
}
#endif

#if swift(>=6.0)
internal typealias VoidClosure = @Sendable () -> Void
/// A closure type for handling image download completion.
///
/// `ImageClosure` is called when an image download completes, providing either
/// the loaded image or `nil` if the download failed.
public typealias ImageClosure = @Sendable (Result<Image, Error>) -> Void
#else
internal typealias VoidClosure = () -> Void
/// A closure type for handling image download completion.
///
/// `ImageClosure` is called when an image download completes, providing either
/// the loaded image or `nil` if the download failed.
public typealias ImageClosure = (Result<Image, Error>) -> Void
#endif

#if os(iOS) || os(tvOS) || supportsVisionOS
import UIKit

public typealias Image = UIImage
public typealias ImageView = UIImageView
#elseif os(macOS)
import Cocoa

public typealias Image = NSImage
public typealias ImageView = NSImageView
#elseif os(watchOS)
import SwiftUI

public typealias Image = UIImage

public protocol ImageView: AnyObject, Sendable {
    var image: Image? { get set }
}

#else
#error("unsupported os")
#endif

#if os(iOS) || os(tvOS)
private enum Screen {
    #if swift(>=6.0)
    @MainActor
    #endif
    static var scale: CGFloat {
        return UIScreen.main.scale
    }
}

#elseif os(watchOS)
import WatchKit

private enum Screen {
    #if swift(>=6.0)
    @MainActor
    #endif
    static var scale: CGFloat {
        return WKInterfaceDevice.current().screenScale
    }

}

#elseif supportsVisionOS
/// Screen utilities for visionOS platform.
///
/// `Screen` provides screen scale information for visionOS, where traditional screen scale
/// concepts don't apply. You can override the scale value for testing purposes.
public enum Screen {
    /// The screen scale factor for visionOS.
    ///
    /// visionOS doesn't have a traditional screen scale, so this defaults to `nil`.
    /// You can override this value for testing purposes, but use with caution.
    @MainActor
    public static var scale: CGFloat?
}
#endif

internal struct PlatformImage {
    let sdk: Image

    init(_ image: Image) {
        self.sdk = image
    }

    #if os(macOS)
    init?(data: Data) {
        if let image = NSImage(data: data) {
            self.init(image)
        } else {
            return nil
        }
    }

    func pngData() -> Data? {
        return sdk.pngData()
    }

    #elseif supportsVisionOS
    init?(data: Data) {
        let scale = Queue.isolatedMain.sync { Screen.scale }

        if let scale,
           let image = UIImage(data: data, scale: scale) {
            self.init(image)
        } else if let image = UIImage(data: data) {
            self.init(image)
        } else {
            return nil
        }
    }

    func pngData() -> Data? {
        return sdk.pngData()
    }

    func jpegData(compressionQuality: CGFloat) -> Data? {
        return sdk.jpegData(compressionQuality: CGFloat(compressionQuality))
    }

    #elseif os(iOS) || os(tvOS) || os(watchOS)
    init?(data: Data) {
        let scale = Queue.isolatedMain.sync { Screen.scale }

        if let image = UIImage(data: data, scale: scale) {
            self.init(image)
        } else {
            return nil
        }
    }

    func pngData() -> Data? {
        return sdk.pngData()
    }

    func jpegData(compressionQuality: CGFloat) -> Data? {
        return sdk.jpegData(compressionQuality: CGFloat(compressionQuality))
    }
    #else
    #error("unsupported os")
    #endif
}

#if os(macOS)
private extension NSBitmapImageRep {
    var png: Data? { representation(using: .png, properties: [:]) }
}

private extension Data {
    var bitmap: NSBitmapImageRep? { NSBitmapImageRep(data: self) }
}

private extension NSImage {
    func pngData() -> Data? {
        return tiffRepresentation?.bitmap?.png
    }
}
#endif
