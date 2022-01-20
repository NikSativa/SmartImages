import Foundation
import NRequest

public final class ModuleFactory {
    public init() {
    }

    public func resolve<E: AnyError>(errorType: E.Type,
                                     requestFactory: AnyRequestManager<E>,
                                     concurrentImagesLimit: ConcurrentImagesLimit = .infinite,
                                     decoders: [ImageDecoder] = []) -> ImageDownloader {
        return Impl.ImageDownloader(requestFactory: requestFactory,
                                    imageCache: resolve(),
                                    operationQueue: resolve(concurrentImagesLimit: concurrentImagesLimit),
                                    imageProcessing: resolve(),
                                    imageDecoding: resolve(decoders: decoders))
    }

    private func resolve() -> FileManager {
        return Impl.FileManager()
    }

    private func resolve() -> ImageCache {
        return Impl.ImageCache(fileManager: resolve())
    }

    private func resolve(concurrentImagesLimit: ConcurrentImagesLimit) -> ImageDownloadQueue {
        return Impl.ImageDownloadQueue(concurrentImagesLimit: concurrentImagesLimit,
                                       operationFactory: resolve())
    }

    private func resolve() -> ImageDownloadOperationFactory {
        return Impl.ImageDownloadOperationFactory()
    }

    private func resolve() -> ImageProcessing {
        return Impl.ImageProcessing()
    }

    private func resolve(decoders: [ImageDecoder]) -> ImageDecoding {
        return Impl.ImageDecoding(decoders: decoders)
    }
}
