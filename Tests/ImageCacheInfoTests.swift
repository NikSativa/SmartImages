import Foundation
import SpryKit
import XCTest

@testable import FastImages
@testable import FastImagesTestHelpers

final class ImageCacheInfoTests: XCTestCase {
    func test_create_with_file_manager() {
        let urls: [URL] = [
            .testMake("file://path/directory"),
            .testMake("file://path/directory/unused")
        ]

        let fileManager: FakeImageDownloaderFileManager = .init()
        fileManager.stub(.urls).andReturn(urls)

        let info = ImageCacheInfo(folderName: "folderName",
                                  fileManager: fileManager)
        XCTAssertEqual(info, ImageCacheInfo(directory: urls[0].appendingPathComponent("folderName", isDirectory: true),
                                            memoryCapacity: 40 * 1024 * 1024,
                                            diskCapacity: 400 * 1024 * 1024))

        let directory: FileManager.SearchPathDirectory = .cachesDirectory
        let domainMask: FileManager.SearchPathDomainMask = .userDomainMask
        XCTAssertHaveReceived(fileManager, .urls, with: directory, domainMask)
    }

    func test_create_with_default_behaviour() {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .cachesDirectory,
                                    in: .userDomainMask)
        let directory = urls.first?.appendingPathComponent("DownloadedImages", isDirectory: true)

        let info = ImageCacheInfo()
        XCTAssertEqual(info, ImageCacheInfo(directory: directory.unsafelyUnwrapped,
                                            memoryCapacity: 40 * 1024 * 1024,
                                            diskCapacity: 400 * 1024 * 1024))
    }
}
