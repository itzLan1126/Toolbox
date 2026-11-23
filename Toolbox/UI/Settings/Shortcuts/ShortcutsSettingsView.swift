import SwiftUI

struct ShortcutsSettingsView: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        Form {
            ForEach(settings.orderedFeatures, id: \.id) { feature in
                LabeledContent {
                    ShortcutManager.recorder(for: feature.id)
                } label: {
                    Label {
                        Text(feature.title)
                    } icon: {
                        Image(systemName: feature.systemImage).foregroundStyle(feature.tint)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(height: 195)
    }
}

#Preview {
    ShortcutsSettingsView()
        .environment(SettingsStore())
}
