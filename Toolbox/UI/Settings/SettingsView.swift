import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }
            FeaturesSettingsView()
                .tabItem { Label("Features", systemImage: "square.grid.2x2") }
            ShortcutsSettingsView()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
            AboutSettingsView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 520)
    }
}

/// Tinted symbol on a soft square of the same tint, as on the Features page.
struct FeatureIcon: View {
    let feature: any Feature

    var body: some View {
        Image(systemName: feature.systemImage)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(feature.tint)
            .frame(width: 24, height: 24)
            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(feature.tint.opacity(0.16)))
    }
}

#Preview {
    SettingsView()
        .environment(SettingsStore())
        .environment(Updater())
}
