import SwiftUI

@main
struct ToolboxApp: App {
    @State private var settings = SettingsStore()
    @State private var updater = Updater()

    init() {
        _ = FeatureRegistry.all // registers global shortcuts at launch
    }

    var body: some Scene {
        MenuBarExtra("Toolbox", image: "MenuBarIcon") {
            MenuBarView()
                .environment(settings)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(settings)
                .environment(updater)
        }
    }
}
