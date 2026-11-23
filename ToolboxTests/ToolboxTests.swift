import CoreGraphics
import XCTest
@testable import Toolbox

final class ToolboxTests: XCTestCase {
    func testCleaningModeOnlyLetsPointerAndLeftClickThrough() {
        for type: CGEventType in [.mouseMoved, .leftMouseDown, .leftMouseUp, .leftMouseDragged] {
            XCTAssertTrue(InputBlocker.allows(type), "\(type.rawValue)")
        }
        let blocked: [CGEventType] = [.keyDown, .keyUp, .flagsChanged, .scrollWheel,
                                      .rightMouseDown, .rightMouseUp, .otherMouseDown, .otherMouseUp]
        for type in blocked { XCTAssertFalse(InputBlocker.allows(type), "\(type.rawValue)") }
        // Gesture / magnify / swipe / media keys (NSEvent types with no CGEventType case).
        for raw: UInt32 in [14, 29, 30, 31, 18, 34] {
            XCTAssertFalse(InputBlocker.allows(CGEventType(rawValue: raw)!), "\(raw)")
        }
    }

    @MainActor func testMenuVisibilityAndOrder() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "hiddenInMenu")
        defaults.removeObject(forKey: "menuOrder")
        defer { defaults.removeObject(forKey: "hiddenInMenu"); defaults.removeObject(forKey: "menuOrder") }

        let store = SettingsStore()
        XCTAssertEqual(store.menuFeatures.map(\.id), ["keepAwake", "hiddenFiles", "cleaningMode"])

        store.setShownInMenu("hiddenFiles", false)
        XCTAssertEqual(store.menuFeatures.map(\.id), ["keepAwake", "cleaningMode"])
        XCTAssertEqual(store.hiddenFeatures.map(\.id), ["hiddenFiles"])

        store.moveMenuFeatures(from: [1], to: 0)
        XCTAssertEqual(store.menuFeatures.map(\.id), ["cleaningMode", "keepAwake"])

        // Persists across launches.
        XCTAssertEqual(SettingsStore().menuFeatures.map(\.id), ["cleaningMode", "keepAwake"])
    }

    func testReorderTargetCoversGapsAndOutside() {
        // Rows at y 0-40, 50-90, 100-140 with 10pt gaps.
        let frames = [0, 50, 100].map { CGRect(x: 0, y: $0, width: 100, height: 40) }
        let target = { (y: CGFloat, from: Int) in FeaturesSettingsView.reorderTarget(y: y, frames: frames, from: from) }
        XCTAssertNil(target(70, 1))      // still over itself
        XCTAssertEqual(target(45, 2), 1) // up into the gap above row 1 → passed row 1
        XCTAssertEqual(target(30, 2), 0) // up onto row 0
        XCTAssertEqual(target(-20, 2), 0) // above everything
        XCTAssertEqual(target(95, 0), 1) // down past row 1 into the gap
        XCTAssertEqual(target(105, 0), 2) // down onto row 2
        XCTAssertEqual(target(300, 0), 2) // below everything
    }
}
