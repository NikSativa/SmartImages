import UIKit

extension Data {
    static func testMake(image: UIImage.TastableImage = .default) -> Self {
        return UIImage.testMake(image).pngData().unsafelyUnwrapped
    }
}
