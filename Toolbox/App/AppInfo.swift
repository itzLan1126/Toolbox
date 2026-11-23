import AppKit

enum AppInfo {
    static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    static let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    static let copyright = Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String ?? ""
    static let gitHubURL = URL(string: "https://github.com/itzLan1126/Toolbox")!

    static func icon(badge: (symbol: String, color: NSColor)? = nil) -> NSImage {
        NSImage(size: NSSize(width: 64, height: 64), flipped: false) { rect in
            NSApp.applicationIconImage.draw(in: rect)

            if let badge {
                let circle = NSRect(x: 38, y: 0, width: 26, height: 26)
                NSColor.white.setFill()
                NSBezierPath(ovalIn: circle).fill()
                badge.color.setFill()
                NSBezierPath(ovalIn: circle.insetBy(dx: 2, dy: 2)).fill()
                let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold).applying(.init(paletteColors: [.white]))
                if let glyph = NSImage(systemSymbolName: badge.symbol, accessibilityDescription: nil)?.withSymbolConfiguration(config) {
                    glyph.draw(in: NSRect(x: circle.midX - glyph.size.width / 2, y: circle.midY - glyph.size.height / 2, width: glyph.size.width, height: glyph.size.height))
                }
            }
            return true
        }
    }
}
