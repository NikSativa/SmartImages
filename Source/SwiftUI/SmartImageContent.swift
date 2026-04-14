#if canImport(SwiftUI)
import SwiftUI

/// Renders a `SmartImagePhase` using a placeholder, optional loader, and a
/// `SmartImageContentScale`. Used by the convenience initializers of
/// `SmartImageView` to produce a strongly-typed `Content`.
public struct SmartImageContent<P: View, L: View>: View {
    private let phase: SmartImagePhase
    private let contentScale: SmartImageContentScale
    private let showLoader: Bool
    private let placeholder: () -> P
    private let loader: () -> L

    @Environment(\.smartImageTransition)
    private var environmentTransition: AnyTransition?

    public init(phase: SmartImagePhase,
                contentScale: SmartImageContentScale,
                showLoader: Bool,
                @ViewBuilder placeholder: @escaping () -> P,
                @ViewBuilder loader: @escaping () -> L) {
        self.phase = phase
        self.contentScale = contentScale
        self.showLoader = showLoader
        self.placeholder = placeholder
        self.loader = loader
    }

    public var body: some View {
        let transition = environmentTransition ?? .identity

        switch phase {
        case .idle,
             .loading:
            ZStack {
                placeholder()

                if showLoader {
                    loader()
                }
            }
            .transition(transition)

        case let .loaded(image, nativeSize):
            Group {
                switch contentScale {
                case .scaledToFit:
                    image
                        .resizable()
                        .scaledToFit()
                case .scaledToFill:
                    image
                        .resizable()
                        .scaledToFill()
                case .stretch:
                    image
                        .resizable()
                case .original:
                    image
                case .scaleDown:
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: nativeSize.width,
                               maxHeight: nativeSize.height)
                }
            }
            .transition(transition)

        case .failed,
             .noURL:
            placeholder()
                .transition(transition)
        }
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
public struct SmartImageResourceView: View {
    private let resource: ImageResource

    init(_ resource: ImageResource) {
        self.resource = resource
    }

    public var body: some View {
        SwiftUI.Image(resource)
            .resizable()
            .scaledToFit()
    }
}

#endif
