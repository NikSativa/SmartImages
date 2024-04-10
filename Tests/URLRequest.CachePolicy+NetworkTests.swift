import Foundation
import SpryKit
import XCTest

@testable import SmartImages

final class URLRequest_CachePolicy_NetworkTests: XCTestCase {
    func test_canUseCachedData() {
        XCTAssertTrue(URLRequest.CachePolicy.returnCacheDataDontLoad.canUseCachedData)
        XCTAssertTrue(URLRequest.CachePolicy.returnCacheDataElseLoad.canUseCachedData)
        XCTAssertTrue(URLRequest.CachePolicy.useProtocolCachePolicy.canUseCachedData)

        XCTAssertFalse(URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData.canUseCachedData)
        XCTAssertFalse(URLRequest.CachePolicy.reloadIgnoringLocalCacheData.canUseCachedData)
        XCTAssertFalse(URLRequest.CachePolicy.reloadRevalidatingCacheData.canUseCachedData)
        XCTAssertFalse(URLRequest.CachePolicy(rawValue: 111)?.canUseCachedData ?? true)
    }
}
