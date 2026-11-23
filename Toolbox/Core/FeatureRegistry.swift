import Foundation

/// Every feature. Register new tools here; menu order is user-defined in `SettingsStore`.
@MainActor
enum FeatureRegistry {
    static let all: [any Feature] = {
        let features: [any Feature] = [
            KeepAwakeFeature(),
            HiddenFilesFeature(),
            CleaningModeFeature(),
        ]
        // Shortcuts work whether or not the feature is shown in the menu.
        features.forEach(ShortcutManager.register)
        return features
    }()
}
