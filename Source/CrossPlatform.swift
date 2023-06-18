import Foundation

internal typealias VoidClosure = () -> Void
public typealias ImageClosure = (Image?) -> Void

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

public typealias Image = UIImage
public typealias ImageView = UIImageView
#elseif os(macOS)
import Cocoa

public typealias Image = NSImage
public typealias ImageView = NSImageView
#else
#error("unsupported os")
#endif

private enum Screen {
    #if os(iOS) || os(tvOS)
    static var scale: CGFloat {
        return UIScreen.main.scale
    }

    #elseif os(watchOS)
    static var scale: CGFloat {
        return WKInterfaceDevice.current().screenScale
    }

    #elseif os(macOS)
    static var scale: CGFloat {
        return 1
    }
    #endif
}

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

    #elseif os(iOS) || os(tvOS) || os(watchOS)
    init?(data: Data) {
        if let image = UIImage(data: data, scale: Screen.scale) {
            self.init(image)
        } else {
            return nil
        }
    }
    #else
    #error("unsupported os")
    #endif
}
