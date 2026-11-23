import AppKit
import SwiftUI

/// One borderless window per screen, above everything, hosting `CleaningView`.
@MainActor
final class CleaningOverlay {
    private var windows: [NSWindow] = []

    init(onExit: @escaping () -> Void) {
        NSApp.activate()
        windows = NSScreen.screens.map { screen in
            let window = KeyableWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: CleaningView(onExit: onExit))
            window.setFrame(screen.frame, display: true)
            window.makeKeyAndOrderFront(nil)
            return window
        }
    }

    func close() {
        windows.forEach { $0.close() }
        windows = []
    }
}

private final class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}
