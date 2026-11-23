import SwiftUI

/// Blocks keyboard/trackpad input behind a full-screen overlay until the user clicks Exit.
@MainActor @Observable
final class CleaningModeFeature: Feature {
    let id = "cleaningMode"
    let title = String(localized: "Cleaning Mode")
    let systemImage = "sparkles"
    let tint = Color.teal
    let requiredPermissions: [Permission] = [.accessibility]
    let closesMenu = true

    private(set) var isOn = false
    @ObservationIgnored private var blocker: InputBlocker?
    @ObservationIgnored private var overlay: CleaningOverlay?
    @ObservationIgnored private var permissionObserver: NSObjectProtocol?

    /// Only starts. The sole way out is the overlay's Exit button.
    func toggle() {
        guard !isOn else { return }

        guard Permissions.isGranted(.accessibility) else {
            Permissions.requestWithAlert(.accessibility, reason: String(localized: "Cleaning Mode needs it to lock the screen and keyboard."))
            return
        }

        let blocker = InputBlocker { [weak self] in self?.verifyPermission() }
        guard blocker.start() else {
            NSApp.activate()
            let alert = NSAlert()
            alert.icon = AppInfo.icon(badge: ("exclamationmark", .systemOrange))
            alert.messageText = String(localized: "Couldn't start Cleaning Mode")
            alert.informativeText = String(localized: "Please try again.")
            alert.runModal()
            return
        }
        self.blocker = blocker

        permissionObserver = DistributedNotificationCenter.default().addObserver(
            forName: Permissions.accessibilityChanged, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.verifyPermission() }
        }

        overlay = CleaningOverlay { [weak self] in self?.stop() }
        isOn = true
    }

    private func stop() {
        blocker?.stop()
        blocker = nil
        overlay?.close()
        overlay = nil
        if let permissionObserver { DistributedNotificationCenter.default().removeObserver(permissionObserver) }
        permissionObserver = nil
        isOn = false
    }

    /// Trust flips slightly after the notification fires, so re-check after a beat.
    private func verifyPermission() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, isOn else { return }
            if Permissions.isGranted(.accessibility) {
                blocker?.reenable()
            } else {
                stop()
            }
        }
    }
}
