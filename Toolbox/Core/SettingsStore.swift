import Foundation
import Observation
import ServiceManagement

/// App preferences shared by the menu bar and the Settings window.
@MainActor @Observable
final class SettingsStore {
    private let defaults = UserDefaults.standard

    private var hiddenInMenu: Set<String> {
        didSet { defaults.set(Array(hiddenInMenu), forKey: "hiddenInMenu") }
    }

    private var menuOrder: [String] {
        didSet { defaults.set(menuOrder, forKey: "menuOrder") }
    }

    /// Mirrors `SMAppService` so the toggle reflects what the system actually did.
    private(set) var launchAtLogin = SMAppService.mainApp.status == .enabled
    var launchAtLoginError: String?

    /// App UI language; `nil` follows the system. Written to `AppleLanguages`, so it applies on next launch.
    var language: String? {
        didSet {
            if let language { defaults.set([language], forKey: "AppleLanguages") } else { defaults.removeObject(forKey: "AppleLanguages") }
        }
    }
    /// The language this process is running with.
    private let launchLanguage: String?
    /// True once the picked language differs from the running one, i.e. a restart is pending.
    var languageNeedsRestart: Bool { language != launchLanguage }

    init() {
        hiddenInMenu = Set(defaults.stringArray(forKey: "hiddenInMenu") ?? [])
        menuOrder = defaults.stringArray(forKey: "menuOrder") ?? []
        // Read the app's own domain only; `defaults.stringArray` would fall through to the system's list.
        let saved = (defaults.persistentDomain(forName: Bundle.main.bundleIdentifier ?? "")?["AppleLanguages"] as? [String])?.first
        language = saved
        launchLanguage = saved
    }

    /// Features in the user's order; ones never ordered keep registry order at the end.
    var orderedFeatures: [any Feature] {
        FeatureRegistry.all.sorted { (menuOrder.firstIndex(of: $0.id) ?? .max) < (menuOrder.firstIndex(of: $1.id) ?? .max) }
    }

    var menuFeatures: [any Feature] { orderedFeatures.filter { !hiddenInMenu.contains($0.id) } }
    var hiddenFeatures: [any Feature] { orderedFeatures.filter { hiddenInMenu.contains($0.id) } }

    func setShownInMenu(_ id: String, _ shown: Bool) {
        if shown { hiddenInMenu.remove(id) } else { hiddenInMenu.insert(id) }
    }

    func moveMenuFeatures(from source: IndexSet, to destination: Int) {
        var visible = menuFeatures.map(\.id)
        visible.move(fromOffsets: source, toOffset: destination)
        menuOrder = visible + hiddenFeatures.map(\.id)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = error.localizedDescription
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}
