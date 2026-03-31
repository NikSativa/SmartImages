#if canImport(SwiftUI)
import Foundation
import SmartImages
import SwiftUI
import Threading

/// A view that asynchronously loads and displays an image from one or more URLs.
///
/// `SmartImageView` supports fallback URLs — if the first URL fails, the next one is tried.
/// While loading, a placeholder with an optional loader overlay is shown.
///
/// ## Usage Example
/// ```swift
/// SmartImageView(url: imageURL, imageFetcher: downloader) {
///     ProgressView()
/// } placeholder: {
///     Image(systemName: "photo")
/// }
/// .smartImageStyle(MyCustomStyle())
/// ```
@MainActor
public struct SmartImageView<P: View, L: View>: View {
    private let loader: () -> L
    private let placeholder: () -> P
    private let requests: [ImageRequest]
    private let showLoader: Bool
    private let imageFetcher: ImageFetching
    private let style: any SmartImageStyle<P, L>

    @SwiftUI.State
    private var reference = ImageDownloadReference()
    @SwiftUI.State
    private var phase: SmartImagePhase
    @SwiftUI.State
    private var loadedRequests: [ImageRequest] = []

    public init(requests: [ImageRequest],
                imageFetcher: ImageFetching,
                showLoader: Bool = true,
                style: (any SmartImageStyle<P, L>)? = nil,
                @ViewBuilder loader: @escaping () -> L,
                @ViewBuilder placeholder: @escaping () -> P) {
        self.requests = requests
        self.showLoader = showLoader
        self.loader = loader
        self.placeholder = placeholder
        self.phase = .idle
        self.imageFetcher = imageFetcher
        self.style = style ?? DefaultSmartImageStyle<P, L>()
    }

    public var body: some View {
        AnyView(style.makeBody(configuration: configuration)
            .task {
                startLoadingIfNeeded()
            })
    }

    private var configuration: SmartImageStyleConfiguration<P, L> {
        .init(phase: phase,
              placeholder: placeholder,
              loader: loader,
              showLoader: showLoader)
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

        phase = .loading
        let request = requests[atIndex]
        imageFetcher.download(of: request, for: reference) { [weak reference] result in
            guard reference === self.reference, requests.contains(request) else {
                return
            }

            switch result {
            case let .success(image):
                loadedRequests = requests
                #if os(iOS) || os(tvOS) || os(watchOS) || supportsVisionOS
                phase = .loaded(.init(uiImage: image))
                #elseif os(macOS)
                phase = .loaded(.init(nsImage: image))
                #endif

            case .failure:
                loadURL(atIndex: atIndex + 1)
            }
        }
    }
}

public extension SmartImageView {
    init(request: ImageRequest?,
         imageFetcher: ImageFetching,
         showLoader: Bool = true,
         style: (any SmartImageStyle<P, L>)? = nil,
         @ViewBuilder loader: @escaping () -> L,
         @ViewBuilder placeholder: @escaping () -> P) {
        self.init(requests: request.map { [$0] } ?? [],
                  imageFetcher: imageFetcher,
                  showLoader: showLoader,
                  style: style,
                  loader: loader,
                  placeholder: placeholder)
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    init(requests: [ImageRequest],
         imageFetcher: ImageFetching,
         placeholder: ImageResource,
         showLoader: Bool = true,
         style: (any SmartImageStyle<SmartImagePlaceholder, L>)? = nil,
         @ViewBuilder loader: @escaping () -> L) where P == SmartImagePlaceholder {
        self.init(requests: requests,
                  imageFetcher: imageFetcher,
                  showLoader: showLoader,
                  style: style,
                  loader: loader,
                  placeholder: {
                      SmartImagePlaceholder(placeholder)
                  })
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    init(request: ImageRequest?,
         imageFetcher: ImageFetching,
         placeholder: ImageResource,
         showLoader: Bool = true,
         style: (any SmartImageStyle<SmartImagePlaceholder, L>)? = nil,
         @ViewBuilder loader: @escaping () -> L) where P == SmartImagePlaceholder {
        self.init(requests: request.map { [$0] } ?? [],
                  imageFetcher: imageFetcher,
                  placeholder: placeholder,
                  showLoader: showLoader,
                  style: style,
                  loader: loader)
    }

    // MARK: URL

    init(urls: [URL],
         imageFetcher: ImageFetching,
         showLoader: Bool = true,
         style: (any SmartImageStyle<P, L>)? = nil,
         @ViewBuilder loader: @escaping () -> L,
         @ViewBuilder placeholder: @escaping () -> P) {
        self.init(requests: urls.map { .init(url: $0) },
                  imageFetcher: imageFetcher,
                  showLoader: showLoader,
                  style: style,
                  loader: loader,
                  placeholder: placeholder)
    }

    init(url: URL?,
         imageFetcher: ImageFetching,
         showLoader: Bool = true,
         style: (any SmartImageStyle<P, L>)? = nil,
         @ViewBuilder loader: @escaping () -> L,
         @ViewBuilder placeholder: @escaping () -> P) {
        self.init(urls: url.map { [$0] } ?? [],
                  imageFetcher: imageFetcher,
                  showLoader: showLoader,
                  style: style,
                  loader: loader,
                  placeholder: placeholder)
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    init(urls: [URL],
         imageFetcher: ImageFetching,
         placeholder: ImageResource,
         showLoader: Bool = true,
         style: (any SmartImageStyle<SmartImagePlaceholder, L>)? = nil,
         @ViewBuilder loader: @escaping () -> L) where P == SmartImagePlaceholder {
        self.init(requests: urls.map { .init(url: $0) },
                  imageFetcher: imageFetcher,
                  placeholder: placeholder,
                  showLoader: showLoader,
                  style: style,
                  loader: loader)
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    init(url: URL?,
         imageFetcher: ImageFetching,
         placeholder: ImageResource,
         showLoader: Bool = true,
         style: (any SmartImageStyle<SmartImagePlaceholder, L>)? = nil,
         @ViewBuilder loader: @escaping () -> L) where P == SmartImagePlaceholder {
        self.init(urls: url.map { [$0] } ?? [],
                  imageFetcher: imageFetcher,
                  placeholder: placeholder,
                  showLoader: showLoader,
                  style: style,
                  loader: loader)
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
public struct SmartImagePlaceholder: View {
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

private final class ImageDownloadReference {}

#endif
