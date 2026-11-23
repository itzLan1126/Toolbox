import SwiftUI

struct AboutSettingsView: View {
    @Environment(Updater.self) private var updater
    @State private var showsLicenses = false

    var body: some View {
        VStack(spacing: 0) {
            Image(nsImage: AppInfo.icon())
                .resizable()
                .frame(width: 96, height: 96)
            Text("Toolbox")
                .font(.title.bold())
                .padding(.top, 8)
            Text("Version \(AppInfo.version) (\(AppInfo.build))")
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            Text("A menu bar toolbox for macOS.")
                .padding(.top, 12)
            HStack {
                Link(destination: AppInfo.gitHubURL) {
                    Label("GitHub", systemImage: "arrow.up.right").labelStyle(TrailingIconLabelStyle())
                }
                .buttonStyle(.bordered)
                Button("Check for Updates…", action: updater.checkForUpdates)
                    .disabled(!updater.isConfigured)
            }
            .padding(.top, 16)
            Spacer()
            Button("Acknowledgements") { showsLicenses = true }
                .buttonStyle(.link)
                .font(.caption)
            Text(AppInfo.copyright)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .padding(.top, 24)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .frame(height: 315)
        .sheet(isPresented: $showsLicenses) { LicensesView() }
    }
}

private struct LicensesView: View {
    @Environment(\.dismiss) private var dismiss
    private let text = Bundle.main.url(forResource: "Acknowledgements", withExtension: "txt")
        .flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ""

    var body: some View {
        VStack(alignment: .trailing) {
            ScrollView {
                Text(text)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button("Done") { dismiss() }
                .keyboardShortcut(.defaultAction)
        }
        .padding()
        .frame(width: 560, height: 400)
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon.imageScale(.small)
        }
    }
}

#Preview {
    AboutSettingsView()
        .environment(Updater())
}
