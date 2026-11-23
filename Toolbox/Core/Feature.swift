import SwiftUI

/// A tool shown in the menu bar and settings. New tools implement this and get registered in `FeatureRegistry`.
@MainActor
protocol Feature: AnyObject, Observable {
    var id: String { get }
    var title: String { get }
    var systemImage: String { get }
    var tint: Color { get }
    /// Declaration only, shown on the Features page. Checking/granting lives in `Permissions`.
    var requiredPermissions: [Permission] { get }
    var isOn: Bool { get }
    func toggle()
    /// Close the menu panel before toggling (e.g. the feature takes over the screen).
    var closesMenu: Bool { get }
}

extension Feature {
    var requiredPermissions: [Permission] { [] }
    var closesMenu: Bool { false }
}
