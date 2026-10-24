import XCTest
@testable import WayShot

final class EditSessionTests: XCTestCase {

    func testInitialState() {
        let session = EditSession()
        XCTAssertFalse(session.canUndo)
        XCTAssertFalse(session.canRedo)
        XCTAssertTrue(session.currentState.adjustments.isDefault())
        XCTAssertNil(session.currentState.selectedPresetId)
    }

    func testPushStateAndUndo() {
        let session = EditSession()
        var newState = session.currentState
        newState.adjustments.brightness = 25.0

        session.pushState(newState)
        XCTAssertTrue(session.canUndo)
        XCTAssertFalse(session.canRedo)
        XCTAssertEqual(session.currentState.adjustments.brightness, 25.0)

        let undoSuccess = session.undo()
        XCTAssertTrue(undoSuccess)
        XCTAssertFalse(session.canUndo)
        XCTAssertTrue(session.canRedo)
        XCTAssertEqual(session.currentState.adjustments.brightness, 0.0)

        let redoSuccess = session.redo()
        XCTAssertTrue(redoSuccess)
        XCTAssertTrue(session.canUndo)
        XCTAssertFalse(session.canRedo)
        XCTAssertEqual(session.currentState.adjustments.brightness, 25.0)
    }

    func testMaxHistoryDepth() {
        let session = EditSession(maxHistoryDepth: 5)
        for i in 1...10 {
            var state = session.currentState
            state.adjustments.brightness = Float(i)
            session.pushState(state)
        }

        XCTAssertEqual(session.currentState.adjustments.brightness, 10.0)

        var undoCount = 0
        while session.undo() {
            undoCount += 1
        }

        XCTAssertEqual(undoCount, 5)
        XCTAssertEqual(session.currentState.adjustments.brightness, 5.0)
    }

    func testReset() {
        let session = EditSession()
        var modified = session.currentState
        modified.adjustments.contrast = 40.0
        session.pushState(modified)

        session.reset()
        XCTAssertTrue(session.currentState.adjustments.isDefault())
        XCTAssertTrue(session.canUndo)
    }
}
