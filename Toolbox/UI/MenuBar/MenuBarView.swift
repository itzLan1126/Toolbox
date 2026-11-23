import SwiftUI

/// The menu-bar panel: one row per visible feature, then Settings and Quit.
struct MenuBarView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(settings.menuFeatures, id: \.id) { feature in
                FeatureMenuRow(feature: feature)
            }
            if !settings.menuFeatures.isEmpty { MenuDivider() }
            MenuRow(systemImage: "gearshape", title: String(localized: "Settings…"), shortcut: "⌘,") {
                closeMenu()
                openSettings()
                // LSUIElement apps aren't activated automatically, and activate() is only a request
                // on macOS 14+, so activate after the window exists and push it to the front.
                DispatchQueue.main.async {
                    NSApp.activate()
                    // ponytail: matches SwiftUI's private Settings window identifier; update if SwiftUI renames it
                    NSApp.windows.first { $0.identifier?.rawValue == "com_apple_SwiftUI_Settings_window" }?
                        .makeKeyAndOrderFront(nil)
                }
            }
            .keyboardShortcut(",")
            MenuDivider()
            MenuRow(systemImage: "power", title: String(localized: "Quit Toolbox"), shortcut: "⌘Q") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(5)
        .frame(width: 260)
    }
}

/// The panel is the key window while it's open.
@MainActor func closeMenu() {
    NSApp.keyWindow?.close()
}

private struct FeatureMenuRow: View {
    let feature: any Feature

    var body: some View {
        MenuRow(systemImage: feature.systemImage, title: feature.title, shortcut: ShortcutManager.shared.label(for: feature.id), action: activate, tint: feature.tint) {
            // Clicks land on the whole row; the switch stays reachable for VoiceOver.
            Toggle(feature.title, isOn: Binding(get: { feature.isOn }, set: { _ in activate() }))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
                .allowsHitTesting(false)
        }
    }

    private func activate() {
        if feature.closesMenu {
            closeMenu()
            DispatchQueue.main.async { feature.toggle() }
        } else {
            feature.toggle()
        }
    }
}

private struct MenuRow<Accessory: View>: View {
    let systemImage: String
    let title: String
    let shortcut: String?
    let action: () -> Void
    var tint: Color = .primary
    @ViewBuilder var accessory: Accessory
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                    .frame(width: 16)
                Text(title)
                Spacer()
                if let shortcut {
                    Text(shortcut).foregroundStyle(.secondary)
                }
                accessory
            }
            .padding(.horizontal, 9)
            .frame(height: 30)
            .contentShape(Rectangle())
            .background(RoundedRectangle(cornerRadius: 6).fill(isHovered ? Color.primary.opacity(0.08) : .clear))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

extension MenuRow where Accessory == EmptyView {
    init(systemImage: String, title: String, shortcut: String?, action: @escaping () -> Void) {
        self.init(systemImage: systemImage, title: title, shortcut: shortcut, action: action) { EmptyView() }
    }
}

private struct MenuDivider: View {
    var body: some View {
        Divider().padding(.horizontal, 9).padding(.vertical, 5)
    }
}

#Preview {
    MenuBarView()
        .environment(SettingsStore())
}
