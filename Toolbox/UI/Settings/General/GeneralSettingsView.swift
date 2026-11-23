import SwiftUI

struct GeneralSettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(Updater.self) private var updater

    var body: some View {
        @Bindable var updater = updater
        @Bindable var settings = settings
        Form {
            Section {
                Picker(selection: $settings.language) {
                    Text("System Default").tag(String?.none)
                    Text("English").tag(String?("en"))
                    Text("简体中文").tag(String?("zh-Hans"))
                } label: {
                    Text("Language")
                    if settings.languageNeedsRestart {
                        Text("Takes effect after restart.")
                    }
                }
                Toggle("Launch at login", isOn: Binding(get: { settings.launchAtLogin }, set: settings.setLaunchAtLogin))
                if let error = settings.launchAtLoginError {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }
            Section("Updates") {
                Toggle("Check for updates automatically", isOn: $updater.automaticallyChecks)
                Toggle("Download and install updates automatically", isOn: $updater.automaticallyDownloads)
                    .disabled(!updater.automaticallyChecks)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Toolbox \(AppInfo.version)")
                        Text("Last checked: \(updater.lastCheck?.formatted(date: .abbreviated, time: .shortened) ?? String(localized: "Never"))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Check for Updates…", action: updater.checkForUpdates)
                        .disabled(!updater.isConfigured)
                }
            }
        }
        .formStyle(.grouped)
        .frame(height: 315)
    }
}

#Preview {
    GeneralSettingsView()
        .environment(SettingsStore())
        .environment(Updater())
}
