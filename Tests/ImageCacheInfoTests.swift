import Foundation
import SmartImages
import SpryKit
import XCTest

final class ImageCacheInfoTests: XCTestCase {
    func test_create_with_file_manager() {
        // less than minimum size
        var subject = ImageCacheInfo(folderName: "folderName_1",
                                     memoryCapacity: 10 * 1024 * 1024,
                                     diskCapacity: 100 * 1024 * 1024)
        XCTAssertEqual(subject?.directory, Self.fileURL(forFolderName: "folderName_1"))
        XCTAssertEqual(subject?.memoryCapacity, 10 * 1024 * 1024)
        XCTAssertEqual(subject?.diskCapacity, 100 * 1024 * 1024)

        // custom size
        subject = ImageCacheInfo(folderName: "folderName_2",
                                 memoryCapacity: 20 * 1024 * 1024,
                                 diskCapacity: 20 * 1024 * 1024)
        XCTAssertEqual(subject?.directory, Self.fileURL(forFolderName: "folderName_2"))
        XCTAssertEqual(subject?.memoryCapacity, 20 * 1024 * 1024)
        XCTAssertEqual(subject?.diskCapacity, 20 * 1024 * 1024)

        // default size
        subject = ImageCacheInfo(folderName: "folderName_3")
        XCTAssertEqual(subject?.directory, Self.fileURL(forFolderName: "folderName_3"))
        XCTAssertEqual(subject?.memoryCapacity, 40 * 1024 * 1024)
        XCTAssertEqual(subject?.diskCapacity, 400 * 1024 * 1024)
    }

    func test_create_with_default_behaviour() {
        let info = ImageCacheInfo()
        XCTAssertEqual(info?.directory, Self.fileURL(forFolderName: "DownloadedImages"))
        XCTAssertEqual(info?.memoryCapacity, 40 * 1024 * 1024)
        XCTAssertEqual(info?.diskCapacity, 400 * 1024 * 1024)
    }

    private static func fileURL(forFolderName name: String) -> URL {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let directory = urls.first?.appendingPathComponent(name, isDirectory: true)
        return directory ?? URL(fileURLWithPath: "unknown path")
    }
}
