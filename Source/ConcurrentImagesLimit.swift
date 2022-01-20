import Foundation

public enum ConcurrentImagesLimit: Equatable {
    case infinite
    case other(Int)
}
