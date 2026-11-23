import SwiftUI

struct FeaturesSettingsView: View {
    @Environment(SettingsStore.self) private var settings
    /// Bumped to re-read permission state, which isn't observable.
    @State private var permissionCheck = 0
    /// Id of the row being dragged; set by `onDrag`, read synchronously on drop.
    @State private var dragging: String?
    /// Row the dragged one would take the place of; drives the highlight.
    @State private var dropTarget: String?
    /// Menu rows' frames in the Form's space, to map the drag location to a row.
    @State private var rowFrames: [String: CGRect] = [:]

    var body: some View {
        Form {
            Section("In Menu Bar") {
                ForEach(settings.menuFeatures, id: \.id) { feature in
                    row(feature, inMenu: true)
                        .contentShape(Rectangle())
                        .onDrag {
                            dragging = feature.id
                            return NSItemProvider(object: feature.id as NSString)
                        }
                        .background(GeometryReader { geo in
                            Color.clear.preference(key: RowFrames.self, value: [feature.id: geo.frame(in: .named(Self.space))])
                        })
                }
                if settings.menuFeatures.isEmpty { placeholder("No features in the menu bar") }
            }
            Section("Hidden from Menu Bar") {
                ForEach(settings.hiddenFeatures, id: \.id) { feature in
                    row(feature, inMenu: false)
                }
                if settings.hiddenFeatures.isEmpty { placeholder("No hidden features") }
            }
        }
        .formStyle(.grouped)
        .coordinateSpace(name: Self.space)
        .onPreferenceChange(RowFrames.self) { rowFrames = $0 }
        // One drop zone for the whole page, so gaps and the space above/below the rows count too.
        .onDrop(of: [.plainText], delegate: ReorderDrop(
            hover: { y in
                let target = y.flatMap(target(at:))
                if target != dropTarget { withAnimation(.easeOut(duration: 0.12)) { dropTarget = target } }
            },
            perform: {
                defer { dragging = nil; dropTarget = nil }
                guard let dragging, let dropTarget else { return false }
                return move(dragging, onto: dropTarget)
            }
        ))
        .frame(height: 340)
        .id(permissionCheck)
        .onReceive(DistributedNotificationCenter.default().publisher(for: Permissions.accessibilityChanged).delay(for: .milliseconds(500), scheduler: RunLoop.main)) { _ in
            permissionCheck += 1
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            permissionCheck += 1
        }
    }

    private static let space = "features"

    private func target(at y: CGFloat) -> String? {
        let ids = settings.menuFeatures.map(\.id)
        guard let dragging, let from = ids.firstIndex(of: dragging),
              let to = Self.reorderTarget(y: y, frames: ids.map { rowFrames[$0] ?? .null }, from: from) else { return nil }
        return ids[to]
    }

    /// Dragging up: the first row whose bottom is below the cursor, i.e. reached or passed.
    /// Dragging down: the last row whose top is above the cursor. Inside its own row: nil.
    static func reorderTarget(y: CGFloat, frames: [CGRect], from: Int) -> Int? {
        let own = frames[from]
        let to: Int?
        if y < own.minY { to = frames.indices.first { y < frames[$0].maxY } }
        else if y > own.maxY { to = frames.indices.last { y > frames[$0].minY } }
        else { to = nil }
        return to == from ? nil : to
    }

    /// `Form` ignores `.onMove`, so rows drag/drop their id manually; drops `id` into `target`'s slot.
    private func move(_ id: String, onto target: String) -> Bool {
        let ids = settings.menuFeatures.map(\.id)
        guard let from = ids.firstIndex(of: id), let to = ids.firstIndex(of: target), from != to else { return false }
        withAnimation { settings.moveMenuFeatures(from: IndexSet(integer: from), to: to > from ? to + 1 : to) }
        return true
    }

    private func row(_ feature: any Feature, inMenu: Bool) -> some View {
        let isTarget = inMenu && dropTarget == feature.id
        return HStack(spacing: 10) {
            Button {
                withAnimation { settings.setShownInMenu(feature.id, !inMenu) }
            } label: {
                Image(systemName: inMenu ? "minus.circle.fill" : "plus.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(inMenu ? String(localized: "Hide from menu bar") : String(localized: "Show in menu bar"))

            FeatureIcon(feature: feature)

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                let missing = feature.requiredPermissions.filter { !Permissions.isGranted($0) }
                ForEach(missing, id: \.self) { permission in
                    HStack(spacing: 8) {
                        Label("Needs \(permission.title)", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 4).fill(.orange.opacity(0.15)))
                        Button("Open System Settings") { Permissions.openSystemSettings(for: permission) }
                            .controlSize(.small)
                    }
                }
            }

            Spacer()

            Toggle(feature.title, isOn: Binding(get: { feature.isOn }, set: { _ in feature.toggle() }))
                .toggleStyle(.switch)
                .labelsHidden()

            Image(systemName: isTarget ? "arrow.up.arrow.down" : "line.3.horizontal")
                .foregroundStyle(isTarget ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                .opacity(inMenu ? 1 : 0)
                .help("Drag to reorder")
        }
        .background {
            if isTarget {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(.tint, lineWidth: 1.5)
                    .background(RoundedRectangle(cornerRadius: 6).fill(.tint.opacity(0.12)))
                    .padding(-5)
            }
        }
    }

    private func placeholder(_ text: LocalizedStringKey) -> some View {
        Text(text).foregroundStyle(.secondary)
    }
}

private struct RowFrames: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

/// Proposes `.move` so the cursor shows no "+" copy badge (`dropDestination` always proposes copy).
private struct ReorderDrop: DropDelegate {
    let hover: (CGFloat?) -> Void
    let perform: () -> Bool

    func dropUpdated(info: DropInfo) -> DropProposal? {
        hover(info.location.y)
        return DropProposal(operation: .move)
    }
    func dropExited(info: DropInfo) { hover(nil) }
    func performDrop(info: DropInfo) -> Bool { perform() }
}

#Preview {
    FeaturesSettingsView()
        .environment(SettingsStore())
}
