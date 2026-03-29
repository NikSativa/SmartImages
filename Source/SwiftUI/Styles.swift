#if canImport(SwiftUI)
import SwiftUI

public typealias DefaultSmartImageStyle = ScaledToFitStyle

public struct ScaledToFitStyle<P: View, L: View>: SmartImageStyle {
    public init() {}

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
            image
                .resizable()
                .scaledToFit()

        case .failed,
             .noURL:
            configuration.placeholder()
        }
    }
}

public struct ScaledToFillStyle<P: View, L: View>: SmartImageStyle {
    public init() {}

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
            image
                .resizable()
                .scaledToFill()

        case .failed,
                .noURL:
            configuration.placeholder()
        }
    }
}

#endif
