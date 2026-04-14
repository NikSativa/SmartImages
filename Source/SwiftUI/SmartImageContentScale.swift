import Foundation

public enum SmartImageContentScale: Sendable {
    /// Resize preserving aspect; image fills container, may crop.
    case scaledToFill
    /// Resize preserving aspect; image fits inside container, no crop.
    case scaledToFit
    /// Resize ignoring aspect; image stretches to fill container.
    case stretch
    /// No resize. Image is rendered at its natural size.
    case original
    /// Like `scaledToFit`, but never upscales beyond the image's natural size.
    case scaleDown
}
