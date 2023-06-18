import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(macOS)
import Cocoa
#else
#error("unsupported os")
#endif

@testable import NImageDownloader

extension Image {
    private static let testImage = Image.colored(.brown)
    private static let testImage1 = Image.colored(.yellow)
    private static let testImage2 = Image.colored(.gray)
    private static let testImage3 = Image.colored(.magenta)
    private static let testImage4 = Image.colored(.green)
    private static let testImage5 = Image.colored(.cyan)

    enum TastableImage {
        case `default`
        case one
        case two
        case three
        case four
        case five
    }

    /// This function returns a the same Image object each time it is called. For example, when you need to use the same image in tests to chech viewState for equality.
    static func testMake(_ image: TastableImage = .default) -> Image {
        switch image {
        case .default:
            return testImage
        case .one:
            return testImage1
        case .two:
            return testImage2
        case .three:
            return testImage3
        case .four:
            return testImage4
        case .five:
            return testImage5
        }
    }

    #if os(iOS) || os(tvOS) || os(watchOS)
    private static func colored(_ color: UIColor) -> Image {
        let size = CGSize(width: 1, height: 1)
        return UIGraphicsImageRenderer(size: size).image { context in
            context.cgContext.setFillColor(color.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
    }

    #elseif os(macOS)
    private static func colored(_ color: NSColor) -> Image {
        let size = NSSize(width: 1, height: 1)
        let image = Image(size: size)
        image.lockFocus()
        color.drawSwatch(in: NSMakeRect(0, 0, size.width, size.height))
        image.unlockFocus()
        return image
    }
    #endif
}

extension PlatformImage {
    #if os(macOS)
    func pngData() -> Data? {
        return sdk.png
    }

    #elseif os(iOS) || os(tvOS) || os(watchOS)
    func pngData() -> Data? {
        return sdk.pngData()
    }
    #else
    #error("unsupported os")
    #endif
}

#if os(macOS)
extension NSBitmapImageRep {
    var png: Data? { representation(using: .png, properties: [:]) }
}

extension Data {
    var bitmap: NSBitmapImageRep? { NSBitmapImageRep(data: self) }
}

extension NSImage {
    var png: Data? { tiffRepresentation?.bitmap?.png }
}
#endif
