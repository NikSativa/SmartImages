#if canImport(SwiftUI)
import SmartImages
import SwiftUI

// MARK: - Keys

private struct SmartImageFetcherKey: EnvironmentKey {
    static let defaultValue: ImageFetching? = nil
}

private struct SmartImageAnimationKey: EnvironmentKey {
    static let defaultValue: Animation? = nil
}

private struct SmartImageTransitionKey: EnvironmentKey {
    #if swift(>=6.0)
    nonisolated(unsafe) static let defaultValue: AnyTransition? = nil
    #else
    static let defaultValue: AnyTransition? = nil
    #endif
}

// MARK: - EnvironmentValues

public extension EnvironmentValues {
    /// Default `ImageFetching` used by `SmartImageView` when no explicit
    /// `imageFetcher:` argument is provided.
    var smartImageFetcher: ImageFetching? {
        get { self[SmartImageFetcherKey.self] }
        set { self[SmartImageFetcherKey.self] = newValue }
    }

    /// Animation applied when `SmartImageView`'s phase transitions to `.loaded`.
    var smartImageAnimation: Animation? {
        get { self[SmartImageAnimationKey.self] }
        set { self[SmartImageAnimationKey.self] = newValue }
    }

    /// Transition applied to the loaded image branch of `SmartImageView`'s
    /// default `SmartImageContent` renderer.
    var smartImageTransition: AnyTransition? {
        get { self[SmartImageTransitionKey.self] }
        set { self[SmartImageTransitionKey.self] = newValue }
    }
}

// MARK: - View modifiers

public extension View {
    /// Injects a default `ImageFetching` for descendant `SmartImageView`s.
    func smartImageFetcher(_ fetcher: ImageFetching) -> some View {
        environment(\.smartImageFetcher, fetcher)
    }

    /// Sets the animation used when the loaded image appears.
    func smartImageAnimation(_ animation: Animation?) -> some View {
        environment(\.smartImageAnimation, animation)
    }

    /// Sets the transition used when the loaded image appears.
    func smartImageTransition(_ transition: AnyTransition?) -> some View {
        environment(\.smartImageTransition, transition)
    }

    /// Convenience: sets both the transition and the animation that drives it.
    func smartImageTransition(_ transition: AnyTransition, animation: Animation?) -> some View {
        environment(\.smartImageTransition, transition)
            .environment(\.smartImageAnimation, animation)
    }
}

#endif
