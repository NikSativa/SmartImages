import Foundation
import NSpry
import XCTest

@testable import NImageDownloader
@testable import NImageDownloaderTestHelpers

final class Image_NetworkTests: XCTestCase {
    func test_sourceURL() {
        let subject = Image()
        XCTAssertNil(subject.sourceURL)

        subject.sourceURL = .testMake("google.com/11")
        XCTAssertEqual(subject.sourceURL, .testMake("google.com/11"))
    }
}
