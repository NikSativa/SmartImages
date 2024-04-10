import Foundation
import SpryKit
import XCTest

@testable import SmartImages

final class ImageCacheTests: XCTestCase {
    func test_should_create_url_cache_with_correct_memory_usage() {
        let url1: URL = .testMake("https://data1.com")
        let url2: URL = .testMake("https://data2.com")

        let data1 = "data1".data(using: .utf8).unsafelyUnwrapped
        let data2 = "data2".data(using: .utf8).unsafelyUnwrapped

        let info = ImageCacheInfo(folderName: "TestImageDownloaderCache")
        XCTAssertNotNil(info)

        let subject: ImageCaching = ImageCache(info: info)
        let urlCache: URLCache = (subject as! ImageCache).urlCache
        XCTAssertEqual(urlCache.diskCapacity, 400 * 1024 * 1024)
        XCTAssertEqual(urlCache.memoryCapacity, 40 * 1024 * 1024)

        var actualData = subject.cached(for: .testMake("https://nodata.com"))
        XCTAssertNil(actualData)

        // rm all stored data previously stored by tests
        subject.removeAll()

        subject.store(data1, for: url1)
        actualData = subject.cached(for: url1)
        XCTAssertEqual(actualData, data1)

        subject.store(data2, for: url2)
        actualData = subject.cached(for: url2)
        XCTAssertEqual(actualData, data2)

        // check the data1 was not overriden by data2
        actualData = subject.cached(for: url1)
        XCTAssertEqual(actualData, data1)

        // rm only one
        subject.remove(for: url1)

        actualData = subject.cached(for: url1)
        XCTAssertNil(actualData)

        actualData = subject.cached(for: url2)
        XCTAssertEqual(actualData, data2)
    }
}
