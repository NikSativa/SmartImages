import Foundation
import NCallback
import NSpry
import UIKit

@testable import NImageDownloader

final class FakeImageDownloading: ImageDownloader, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case startDownloading = "startDownloading(of:)"
        case startDownloadingToImageView = "startDownloading(of:for:)"

        case cancelDownloading = "cancelDownloading(of:)"
        case cancelDownloadingForImageView = "cancelDownloading(for:)"

        case startPrefetching = "startPrefetching(of:)"
        case cancelPrefetching = "cancelPrefetching(of:)"
    }

    init() {}

    func startDownloading(of info: ImageInfo) -> Callback<UIImage?> {
        return spryify(arguments: info)
    }

    func startDownloading(of info: ImageInfo, for imageView: UIImageView) -> Callback<UIImage?> {
        return spryify(arguments: info, imageView)
    }

    func startDownloading(of url: URL) -> Callback<UIImage?> {
        return spryify(arguments: url)
    }

    func startDownloading(of url: URL, for imageView: UIImageView) -> Callback<UIImage?> {
        return spryify(arguments: url, imageView)
    }

    func cancelDownloading(of infos: [ImageInfo]) {
        return spryify(arguments: infos)
    }

    func cancelDownloading(of info: ImageInfo) {
        return spryify(arguments: info)
    }

    func cancelDownloading(of urls: [URL]) {
        return spryify(arguments: urls)
    }

    func cancelDownloading(of url: URL) {
        return spryify(arguments: url)
    }

    func cancelDownloading(for imageView: UIImageView) {
        return spryify(arguments: imageView)
    }

    func startPrefetching(of infos: [ImageInfo]) {
        return spryify(arguments: infos)
    }

    func startPrefetching(of info: ImageInfo) {
        return spryify(arguments: info)
    }

    func startPrefetching(of urls: [URL]) {
        return spryify(arguments: urls)
    }

    func startPrefetching(of url: URL) {
        return spryify(arguments: url)
    }

    func cancelPrefetching(of infos: [ImageInfo]) {
        return spryify(arguments: infos)
    }

    func cancelPrefetching(of info: ImageInfo) {
        return spryify(arguments: info)
    }

    func cancelPrefetching(of urls: [URL]) {
        return spryify(arguments: urls)
    }

    func cancelPrefetching(of url: URL) {
        return spryify(arguments: url)
    }
}
