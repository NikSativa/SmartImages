#if canImport(SwiftUI)
import SwiftUI

public struct SmartImageStyleConfiguration<P: View, L: View> {
    public let phase: SmartImagePhase
    public let placeholder: () -> P
    public let loader: () -> L
    public let showLoader: Bool
    /// Natural pixel size of the loaded image, when available.
    public let nativeSize: CGSize?
}
#endif
