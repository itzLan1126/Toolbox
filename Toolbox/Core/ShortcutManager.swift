import KeyboardShortcuts
import SwiftUI

/// The only place that knows about KeyboardShortcuts. Shortcuts are keyed by feature id and stored in UserDefaults.
@MainActor @Observable
final class ShortcutManager {
    static let shared = ShortcutManager()

    /// Bumped whenever any shortcut changes so labels re-render.
    private var revision = 0

    private init() {
        // ponytail: library-internal notification name; if it ever changes, labels refresh on next launch only.
        NotificationCenter.default.addObserver(forName: .init("KeyboardShortcuts_shortcutByNameDidChange"), object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { ShortcutManager.shared.revision += 1 }
        }
    }

    static func register(_ feature: any Feature) {
        _ = shared
        KeyboardShortcuts.onKeyUp(for: .init(feature.id)) { [weak feature] in
            feature?.toggle()
        }
    }

    /// e.g. "⌃⌥⌘A", or nil when unset.
    func label(for id: String) -> String? {
        _ = revision
        return KeyboardShortcuts.getShortcut(for: .init(id))?.description
    }

    /// Set / change / clear control for the Shortcuts page.
    static func recorder(for id: String) -> some View {
        KeyboardShortcuts.Recorder(for: .init(id))
    }
}
