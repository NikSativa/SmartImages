#if canImport(SwiftUI)
import SwiftUI

public struct SmartImageContentScaleStyle<P: View, L: View>: SmartImageStyle {
    let contentScale: SmartImageContentScale

    @ViewBuilder
    public func makeBody(configuration: SmartImageStyleConfiguration<P, L>) -> some View {
        switch configuration.phase {
        case .idle,
             .loading:
            ZStack {
                configuration.placeholder()

                if configuration.showLoader {
                    configuration.loader()
                }
            }

        case let .loaded(image):
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
                    .frame(maxWidth: configuration.nativeSize?.width,
                           maxHeight: configuration.nativeSize?.height)
            }

        case .failed,
             .noURL:
            configuration.placeholder()
        }
    }
}

#endif
