import Foundation

internal extension URL {
    static func testMake(_ string: String = "https://google.com") -> Self {
        return .init(string: string).unsafelyUnwrapped
    }
}
