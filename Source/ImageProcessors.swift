import CoreGraphics
import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Resize

public extension ImageProcessors {
    /// Resizes an image to a target size.
    ///
    /// - Parameters:
    ///   - size: Target size in points.
    ///   - contentMode: How the image is fitted into the target rectangle.
    struct Resize {
        public enum ContentMode: Sendable {
            /// Resize to exactly `size`, ignoring aspect ratio.
            case stretch
            /// Resize preserving aspect, fitting inside `size` (no crop).
            case aspectFit
            /// Resize preserving aspect, filling `size` (may overflow on one axis).
            case aspectFill
        }

        let size: CGSize
        let contentMode: ContentMode

        public init(size: CGSize, contentMode: ContentMode = .aspectFit) {
            self.size = size
            self.contentMode = contentMode
        }
    }
}

extension ImageProcessors.Resize: ImageProcessor {
    public func process(_ image: SmartImage) -> SmartImage {
        guard let cgImage = image.cg else {
            return image
        }

        let source = CGSize(width: cgImage.width, height: cgImage.height)
        let target = targetSize(for: source)

        guard target.width > 0, target.height > 0 else {
            return image
        }

        guard let context = CGContext(data: nil,
                                      width: Int(target.width.rounded()),
                                      height: Int(target.height.rounded()),
                                      bitsPerComponent: 8,
                                      bytesPerRow: 0,
                                      space: cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return image
        }

        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(origin: .zero, size: target))

        guard let scaled = context.makeImage() else {
            return image
        }

        return scaled.smartImage ?? image
    }

    private func targetSize(for source: CGSize) -> CGSize {
        switch contentMode {
        case .stretch:
            return size
        case .aspectFit:
            let scale = min(size.width / source.width, size.height / source.height)
            return CGSize(width: source.width * scale, height: source.height * scale)
        case .aspectFill:
            let scale = max(size.width / source.width, size.height / source.height)
            return CGSize(width: source.width * scale, height: source.height * scale)
        }
    }
}

// MARK: - Crop

public extension ImageProcessors {
    /// Crops an image to a sub-rectangle, in image-pixel coordinates.
    struct Crop {
        let rect: CGRect

        public init(rect: CGRect) {
            self.rect = rect
        }
    }
}

extension ImageProcessors.Crop: ImageProcessor {
    public func process(_ image: SmartImage) -> SmartImage {
        guard let cgImage = image.cg else {
            return image
        }

        let bounds = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        let clamped = rect.intersection(bounds)
        guard !clamped.isNull, !clamped.isEmpty else {
            return image
        }

        guard let cropped = cgImage.cropping(to: clamped) else {
            return image
        }

        return cropped.smartImage ?? image
    }
}

// MARK: - Bridging

private extension SmartImage {
    var cg: CGImage? {
        #if canImport(UIKit)
        return cgImage
        #elseif canImport(AppKit)
        var rect = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &rect, context: nil, hints: nil)
        #else
        return nil
        #endif
    }
}

private extension CGImage {
    var smartImage: SmartImage? {
        #if canImport(UIKit)
        return UIImage(cgImage: self)
        #elseif canImport(AppKit)
        return NSImage(cgImage: self, size: CGSize(width: width, height: height))
        #else
        return nil
        #endif
    }
}

#if swift(>=6.0)
extension ImageProcessors.Resize: Sendable {}
extension ImageProcessors.Crop: Sendable {}
#endif
