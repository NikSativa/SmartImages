#if canImport(SwiftUI)
import Foundation
import SmartImages
import SwiftUI

/// A view that asynchronously loads and displays an image from one or more URLs.
///
/// Mirrors the shape of SwiftUI's `AsyncImage`, with three additions:
/// fallback URL list, reference-based deduplication via `ImageFetching`, and
/// environment-driven fetcher/animation/transition.
///
/// The canonical initializer takes a phase-builder closure for full control.
/// Convenience initializers accept a `placeholder` + `loader` + `contentScale`
/// to render the loaded image automatically.
///
/// ## Phase-builder usage
/// ```swift
/// SmartImageView(url: imageURL) { phase in
///     switch phase {
///     case .idle, .loading: ProgressView()
///     case .loaded(let image, _): image.resizable().scaledToFit()
///     case .failed, .noURL: Image(systemName: "photo")
///     }
/// }
/// ```
///
/// ## Convenience usage
/// ```swift
/// SmartImageView(url: imageURL, contentScale: .scaledToFill) {
///     ProgressView()
/// } placeholder: {
///     Color.gray
/// }
/// ```
@MainActor
public struct SmartImageView<Content: View>: View {
    private let requests: [ImageRequest]
    private let explicitFetcher: ImageFetching?
    private let content: (SmartImagePhase) -> Content

    @Environment(\.smartImageFetcher)
    private var environmentFetcher: ImageFetching?
    @Environment(\.smartImageAnimation)
    private var environmentAnimation: Animation?

    @SwiftUI.State
    private var reference = ImageDownloadReference()
    @SwiftUI.State
    private var phase: SmartImagePhase = .idle
    @SwiftUI.State
    private var loadedRequests: [ImageRequest] = []

    // MARK: - Phase-builder initializers

    public init(requests: [ImageRequest],
                imageFetcher: ImageFetching? = nil,
                @ViewBuilder content: @escaping (SmartImagePhase) -> Content) {
        self.requests = requests
        self.explicitFetcher = imageFetcher
        self.content = content
    }

    public init(request: ImageRequest?,
                imageFetcher: ImageFetching? = nil,
                @ViewBuilder content: @escaping (SmartImagePhase) -> Content) {
        self.init(requests: request.map { [$0] } ?? [],
                  imageFetcher: imageFetcher,
                  content: content)
    }

    public init(urls: [URL],
                imageFetcher: ImageFetching? = nil,
                @ViewBuilder content: @escaping (SmartImagePhase) -> Content) {
        self.init(requests: urls.map { .init(url: $0) },
                  imageFetcher: imageFetcher,
                  content: content)
    }

    public init(url: URL?,
                imageFetcher: ImageFetching? = nil,
                @ViewBuilder content: @escaping (SmartImagePhase) -> Content) {
        self.init(urls: url.map { [$0] } ?? [],
                  imageFetcher: imageFetcher,
                  content: content)
    }

    public var body: some View {
        content(phase)
            .task(id: requests) {
                startLoadingIfNeeded()
            }
    }

    private func startLoadingIfNeeded() {
        guard phase.shouldFetch || loadedRequests != requests else {
            return
        }

        guard !requests.isEmpty else {
            phase = .noURL
            return
        }

        loadURL(atIndex: 0)
    }

    private func loadURL(atIndex: Int) {
        guard atIndex < requests.count else {
            phase = .failed
            return
        }

        guard let imageFetcher = explicitFetcher ?? environmentFetcher else {
            assertionFailure("SmartImageView requires an `imageFetcher:` argument or `.smartImageFetcher(_:)` in the environment.")
            phase = .failed
            return
        }

        phase = .loading
        let request = requests[atIndex]
        imageFetcher.download(of: request, for: reference) { [weak reference] result in
            guard reference === self.reference, requests.contains(request) else {
                return
            }

            switch result {
            case let .success(image):
                loadedRequests = requests
                let nativeSize = image.size
                #if os(iOS) || os(tvOS) || os(watchOS) || supportsVisionOS
                let swiftUIImage = SwiftUI.Image(uiImage: image)
                #elseif os(macOS)
                let swiftUIImage = SwiftUI.Image(nsImage: image)
                #endif
                withAnimation(environmentAnimation) {
                    phase = .loaded(swiftUIImage, nativeSize: nativeSize)
                }

            case .failure:
                loadURL(atIndex: atIndex + 1)
            }
        }
    }
}

// MARK: - Convenience initializers (placeholder + loader + contentScale)

public extension SmartImageView {
    init<P: View, L: View>(requests: [ImageRequest],
                           imageFetcher: ImageFetching? = nil,
                           showLoader: Bool = true,
                           contentScale: SmartImageContentScale = .scaledToFit,
                           @ViewBuilder loader: @escaping () -> L,
                           @ViewBuilder placeholder: @escaping () -> P) where Content == SmartImageContent<P, L> {
        self.init(requests: requests, imageFetcher: imageFetcher) { phase in
            SmartImageContent(phase: phase,
                              contentScale: contentScale,
                              showLoader: showLoader,
                              placeholder: placeholder,
                              loader: loader)
        }
    }

    init<P: View, L: View>(request: ImageRequest?,
                           imageFetcher: ImageFetching? = nil,
                           showLoader: Bool = true,
                           contentScale: SmartImageContentScale = .scaledToFit,
                           @ViewBuilder loader: @escaping () -> L,
                           @ViewBuilder placeholder: @escaping () -> P) where Content == SmartImageContent<P, L> {
        self.init(requests: request.map { [$0] } ?? [],
                  imageFetcher: imageFetcher,
                  showLoader: showLoader,
                  contentScale: contentScale,
                  loader: loader,
                  placeholder: placeholder)
    }

    init<P: View, L: View>(urls: [URL],
                           imageFetcher: ImageFetching? = nil,
                           showLoader: Bool = true,
                           contentScale: SmartImageContentScale = .scaledToFit,
                           @ViewBuilder loader: @escaping () -> L,
                           @ViewBuilder placeholder: @escaping () -> P) where Content == SmartImageContent<P, L> {
        self.init(requests: urls.map { .init(url: $0) },
                  imageFetcher: imageFetcher,
                  showLoader: showLoader,
                  contentScale: contentScale,
                  loader: loader,
                  placeholder: placeholder)
    }

    init<P: View, L: View>(url: URL?,
                           imageFetcher: ImageFetching? = nil,
                           showLoader: Bool = true,
                           contentScale: SmartImageContentScale = .scaledToFit,
                           @ViewBuilder loader: @escaping () -> L,
                           @ViewBuilder placeholder: @escaping () -> P) where Content == SmartImageContent<P, L> {
        self.init(urls: url.map { [$0] } ?? [],
                  imageFetcher: imageFetcher,
                  showLoader: showLoader,
                  contentScale: contentScale,
                  loader: loader,
                  placeholder: placeholder)
    }
}

// MARK: - Convenience initializers (ImageResource placeholder + loader + contentScale)

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
public extension SmartImageView {
    init<L: View>(requests: [ImageRequest],
                  imageFetcher: ImageFetching? = nil,
                  placeholder: ImageResource,
                  showLoader: Bool = true,
                  contentScale: SmartImageContentScale = .scaledToFit,
                  @ViewBuilder loader: @escaping () -> L) where Content == SmartImageContent<SmartImageResourceView, L> {
        self.init(requests: requests,
                  imageFetcher: imageFetcher,
                  showLoader: showLoader,
                  contentScale: contentScale,
                  loader: loader,
                  placeholder: { SmartImageResourceView(placeholder) })
    }

    init<L: View>(request: ImageRequest?,
                  imageFetcher: ImageFetching? = nil,
                  placeholder: ImageResource,
                  showLoader: Bool = true,
                  contentScale: SmartImageContentScale = .scaledToFit,
                  @ViewBuilder loader: @escaping () -> L) where Content == SmartImageContent<SmartImageResourceView, L> {
        self.init(requests: request.map { [$0] } ?? [],
                  imageFetcher: imageFetcher,
                  placeholder: placeholder,
                  showLoader: showLoader,
                  contentScale: contentScale,
                  loader: loader)
    }

    init<L: View>(urls: [URL],
                  imageFetcher: ImageFetching? = nil,
                  placeholder: ImageResource,
                  showLoader: Bool = true,
                  contentScale: SmartImageContentScale = .scaledToFit,
                  @ViewBuilder loader: @escaping () -> L) where Content == SmartImageContent<SmartImageResourceView, L> {
        self.init(requests: urls.map { .init(url: $0) },
                  imageFetcher: imageFetcher,
                  placeholder: placeholder,
                  showLoader: showLoader,
                  contentScale: contentScale,
                  loader: loader)
    }

    init<L: View>(url: URL?,
                  imageFetcher: ImageFetching? = nil,
                  placeholder: ImageResource,
                  showLoader: Bool = true,
                  contentScale: SmartImageContentScale = .scaledToFit,
                  @ViewBuilder loader: @escaping () -> L) where Content == SmartImageContent<SmartImageResourceView, L> {
        self.init(urls: url.map { [$0] } ?? [],
                  imageFetcher: imageFetcher,
                  placeholder: placeholder,
                  showLoader: showLoader,
                  contentScale: contentScale,
                  loader: loader)
    }
}

private final class ImageDownloadReference {}

#endif
