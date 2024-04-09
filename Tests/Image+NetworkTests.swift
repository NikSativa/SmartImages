import Foundation
import SpryKit
import XCTest

@testable import FastImages
@testable import FastImagesTestHelpers

final class Image_NetworkTests: XCTestCase {
    func test_sourceURL() {
        let subject = Image()
        XCTAssertNil(subject.sourceURL)

        subject.sourceURL = .testMake("google.com/11")
        XCTAssertEqual(subject.sourceURL, .testMake("google.com/11"))
    }
}
