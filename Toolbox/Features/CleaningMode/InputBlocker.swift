import CoreGraphics
import Foundation

/// A session event tap that swallows everything except single-finger pointer movement and left clicks.
/// Exists only while Cleaning Mode is running.
@MainActor
final class InputBlocker {
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private let onDisabledByUser: () -> Void

    init(onDisabledByUser: @escaping () -> Void) {
        self.onDisabledByUser = onDisabledByUser
    }

    func start() -> Bool {
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask.max, // every type, incl. gestures and media keys
            callback: { _, type, event, info in
                let blocker = Unmanaged<InputBlocker>.fromOpaque(info!).takeUnretainedValue()
                return MainActor.assumeIsolated { blocker.handle(type, event) }
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }

        self.tap = tap
        source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        guard let tap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        CFMachPortInvalidate(tap)
        self.tap = nil
        source = nil
    }

    func reenable() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
    }

    /// Keep this light: the system disables slow taps.
    private func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .tapDisabledByTimeout:
            reenable()
            return nil
        case .tapDisabledByUserInput:
            onDisabledByUser()
            return nil
        default:
            return Self.allows(type) ? Unmanaged.passUnretained(event) : nil
        }
    }

    /// Pointer movement and left clicks only, so the Exit button stays reachable.
    /// Keyboard, scroll, gestures, right/other clicks and media keys are swallowed.
    nonisolated static func allows(_ type: CGEventType) -> Bool {
        [.mouseMoved, .leftMouseDown, .leftMouseUp, .leftMouseDragged].contains(type)
    }
}
