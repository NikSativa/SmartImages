import Foundation
import NCallback
import NSpry
import UIKit

@testable import NImageDownloader
@testable import NRequestTestHelpers

extension ImageInfo: Equatable, SpryEquatable {
    public static func testMake(url: URL = .testMake(),
                                animation: Animation? = nil,
                                cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad,
                                timeoutInterval: TimeInterval = 60,
                                placeholder: Placeholder = .ignore,
                                processors: [ImageProcessor] = [],
                                priority: Priority = .default) -> Self {
        return .init(url: url,
                     animation: animation,
                     cachePolicy: cachePolicy,
                     timeoutInterval: timeoutInterval,
                     placeholder: placeholder,
                     processors: processors,
                     priority: priority)
    }

    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.url == rhs.url
            && lhs.animation == rhs.animation
            && lhs.cachePolicy == rhs.cachePolicy
            && lhs.timeoutInterval == rhs.timeoutInterval
            && lhs.placeholder == rhs.placeholder
            && lhs.processors == rhs.processors
    }
}

extension Array where Element == ImageProcessor {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.count == rhs.count &&
            zip(lhs, rhs).lazy.map { String(reflecting: $0) == String(reflecting: $1) }.contains(false)
    }
}
