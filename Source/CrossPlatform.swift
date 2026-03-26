import Foundation
import Threading

#if swift(>=6.0)
public typealias VoidClosure = @Sendable () -> Void
/// A closure type for handling image download completion.
///
/// `ImageClosure` is called when an image download completes, providing either
/// the loaded image or `nil` if the download failed.
public typealias ImageClosure = @Sendable @MainActor (Result<SmartImage, Error>) -> Void
#else
public typealias VoidClosure = () -> Void
/// A closure type for handling image download completion.
///
/// `ImageClosure` is called when an image download completes, providing either
/// the loaded image or `nil` if the download failed.
public typealias ImageClosure = (Result<SmartImage, Error>) -> Void
#endif

#if os(iOS) || os(tvOS) || supportsVisionOS
import UIKit

public typealias SmartImage = UIImage
public typealias SmartImageView = UIImageView
#elseif os(macOS)
import Cocoa

public typealias SmartImage = NSImage
public typealias SmartImageView = NSImageView
#elseif os(watchOS)
import SwiftUI

public typealias SmartImage = UIImage

/// An abstraction over platform image views for watchOS where `UIImageView` is unavailable.
public protocol SmartImageView: AnyObject, Sendable {
    var image: SmartImage? { get set }
}

#else
#error("unsupported os")
#endif

#if os(iOS) || os(tvOS)
private enum DisplayInfo {
    #if swift(>=6.0)
    @MainActor
    #endif
    static var scale: CGFloat {
        return UIScreen.main.scale
    }
}

#elseif os(watchOS)
import WatchKit

private enum DisplayInfo {
    #if swift(>=6.0)
    @MainActor
    #endif
    static var scale: CGFloat {
        return WKInterfaceDevice.current().screenScale
    }
}

#elseif supportsVisionOS
/// DisplayInfo utilities for visionOS platform.
///
/// `DisplayInfo` provides screen scale information for visionOS, where traditional screen scale
/// concepts don't apply. You can override the scale value for testing purposes.
public enum DisplayInfo {
    // The screen scale factor for visionOS.
    //
    // visionOS doesn't have a traditional screen scale, so this defaults to `nil`.
    // You can override this value for testing purposes, but use with caution.
    #if swift(>=6.0)
    @MainActor
    #endif
    public static var scale: CGFloat?
}
#endif

internal struct PlatformImage {
    let sdk: SmartImage

    init(_ image: SmartImage) {
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
        let scale = Queue.isolatedMain.sync { DisplayInfo.scale }

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

    #elseif os(iOS) || os(tvOS) || os(watchOS)
    init?(data: Data) {
        let scale = Queue.isolatedMain.sync { DisplayInfo.scale }

        if let image = UIImage(data: data, scale: scale) {
            self.init(image)
        } else {
            return nil
        }
    }

    func pngData() -> Data? {
        return sdk.pngData()
    }
    #else
    #error("unsupported os")
    #endif
}

#if os(macOS)
private extension NSBitmapImageRep {
    var png: Data? {
        representation(using: .png, properties: [:])
    }
}

private extension Data {
    var bitmap: NSBitmapImageRep? {
        NSBitmapImageRep(data: self)
    }
}

private extension NSImage {
    func pngData() -> Data? {
        return tiffRepresentation?.bitmap?.png
    }
}
#endif
