import IOKit.pwr_mgt
import SwiftUI

/// Holds a PreventUserIdleDisplaySleep assertion while on. The system drops it if the process exits.
@MainActor @Observable
final class KeepAwakeFeature: Feature {
    let id = "keepAwake"
    let title = String(localized: "Keep Awake")
    let systemImage = "sun.max.fill"
    let tint = Color.orange

    private var assertionID: IOPMAssertionID = 0
    private(set) var isOn = false

    func toggle() {
        if isOn {
            IOPMAssertionRelease(assertionID)
            isOn = false
        } else {
            isOn = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "Toolbox Keep Awake" as CFString,
                &assertionID
            ) == kIOReturnSuccess
        }
    }
}
