#if canImport(SwiftUI)
import SwiftUI

public protocol SmartImageStyle<P, L>: Sendable {
    associatedtype Body: View
    associatedtype P: View
    associatedtype L: View

    @ViewBuilder
    func makeBody(configuration: SmartImageStyleConfiguration<P, L>) -> Body
}

#endif
