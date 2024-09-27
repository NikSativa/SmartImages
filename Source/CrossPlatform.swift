import Foundation
import Threading

#if swift(>=6.0)
internal typealias VoidClosure = @Sendable () -> Void
public typealias ImageClosure = @Sendable (Image?) -> Void
#else
internal typealias VoidClosure = () -> Void
public typealias ImageClosure = (Image?) -> Void
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
public protocol ImageView: AnyObject {
    var image: Image? { get set }
}

#else
#error("unsupported os")
#endif

#if os(iOS) || os(tvOS)
private enum Screen {
    @MainActor static var scale: CGFloat {
        return UIScreen.main.scale
    }
}

#elseif os(watchOS)
import WatchKit

private enum Screen {
    @MainActor static var scale: CGFloat {
        return WKInterfaceDevice.current().screenScale
    }
}

#elseif supportsVisionOS
public enum Screen {
    /// visionOS doesn't have a screen scale, so we'll just use 2x for Tests.
    /// override it on your own risk.
    @MainActor public static var scale: CGFloat?
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
