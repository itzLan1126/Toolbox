import SwiftUI

/// Flips Finder's AppleShowAllFiles preference and restarts Finder.
@MainActor @Observable
final class HiddenFilesFeature: Feature {
    let id = "hiddenFiles"
    let title = String(localized: "Show Hidden Files")
    let systemImage = "eye.fill"
    let tint = Color.indigo

    private static let key = "AppleShowAllFiles" as CFString
    private static let finder = "com.apple.finder" as CFString

    private(set) var isOn = HiddenFilesFeature.read()

    func toggle() {
        let newValue = !Self.read() // re-read in case it was changed elsewhere (e.g. ⌘⇧. or `defaults`)
        CFPreferencesSetAppValue(Self.key, newValue as CFBoolean, Self.finder)
        CFPreferencesAppSynchronize(Self.finder)
        isOn = Self.read()
        _ = try? Process.run(URL(fileURLWithPath: "/usr/bin/killall"), arguments: ["Finder"])
    }

    private static func read() -> Bool {
        CFPreferencesAppSynchronize(finder)
        let value = CFPreferencesCopyAppValue(key, finder)
        // Older macOS wrote "YES"/"TRUE" strings; accept either form.
        if let b = value as? Bool { return b }
        if let s = value as? String { return ["yes", "true", "1"].contains(s.lowercased()) }
        return false
    }
}
