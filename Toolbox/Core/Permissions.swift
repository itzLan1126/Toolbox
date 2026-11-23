import AppKit
import ApplicationServices

enum Permission: String, CaseIterable {
    case accessibility

    var title: String {
        switch self {
        case .accessibility: String(localized: "Accessibility")
        }
    }
}

/// Checks permissions and guides the user to grant them. Never prompts on its own.
@MainActor
enum Permissions {
    /// Fires when any app's accessibility trust changes.
    static let accessibilityChanged = Notification.Name("com.apple.accessibility.api")

    static func isGranted(_ permission: Permission) -> Bool {
        switch permission {
        case .accessibility: AXIsProcessTrusted()
        }
    }

    static func openSystemSettings(for permission: Permission) {
        switch permission {
        case .accessibility:
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }

    /// Native alert explaining why the permission is needed.
    static func requestWithAlert(_ permission: Permission, reason: String) {
        NSApp.activate()
        let alert = NSAlert()
        alert.icon = AppInfo.icon(badge: ("accessibility", .systemBlue))
        alert.messageText = String(localized: "Allow \(permission.title) access")
        alert.informativeText = reason
        alert.addButton(withTitle: String(localized: "Open System Settings"))
        alert.addButton(withTitle: String(localized: "Cancel"))
        if alert.runModal() == .alertFirstButtonReturn {
            openSystemSettings(for: permission)
        }
    }
}
