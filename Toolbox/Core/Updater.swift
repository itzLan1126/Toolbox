import Sparkle
import SwiftUI

/// Wraps Sparkle so the rest of the app doesn't import it.
@MainActor @Observable
final class Updater {
    @ObservationIgnored private let controller: SPUStandardUpdaterController
    private var updater: SPUUpdater { controller.updater }
    let isConfigured: Bool

    init() {
        // ponytail: Sparkle errors without an EdDSA key; stay dormant until SUPublicEDKey is set in project.yml.
        let key = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String ?? ""
        isConfigured = !key.isEmpty
        controller = SPUStandardUpdaterController(startingUpdater: isConfigured, updaterDelegate: nil, userDriverDelegate: nil)
        automaticallyChecks = controller.updater.automaticallyChecksForUpdates
        automaticallyDownloads = controller.updater.automaticallyDownloadsUpdates
    }

    var automaticallyChecks: Bool {
        didSet { updater.automaticallyChecksForUpdates = automaticallyChecks }
    }

    var automaticallyDownloads: Bool {
        didSet { updater.automaticallyDownloadsUpdates = automaticallyDownloads }
    }

    var lastCheck: Date? { updater.lastUpdateCheckDate }

    func checkForUpdates() {
        NSApp.activate()
        controller.checkForUpdates(nil)
    }
}
