import Foundation

internal extension URLRequest {
    static func testMake(name: String) -> Self {
        // cached response needs fulfilled url with all parameters as from real request
        let parts = ["https://www.google.com/image/", name, ".png"].joined()
        return .testMake(url: parts)
    }

    static func testMake(url: String = "https://www.google.com") -> Self {
        return .init(url: .testMake(url))
    }
}
