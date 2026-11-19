import XCTest
@testable import FaceLiveness

final class LivenessGuidanceTests: XCTestCase {
    func testBeforeTheOvalItAsksToLookAtTheCamera() {
        let states: [LivenessStateMachine.State] = [
            .initial,
            .pendingFacePreparedConfirmation(.pendingCheck),
            .waitForRecording,
            .recording(ovalDisplayed: false)
        ]

        for state in states {
            let guidance = LivenessGuidance(state: state)
            XCTAssertEqual(guidance, .lookAtCamera, "\(state)")
            XCTAssertFalse(guidance.showsOval)
            XCTAssertEqual(guidance.progress, 0)
        }
    }

    func testOnceTheOvalIsShownItAsksToLeanIn() {
        let guidance = LivenessGuidance(state: .recording(ovalDisplayed: true))

        XCTAssertEqual(guidance.title, LocalizedStrings.guidance_lean_in_title)
        XCTAssertTrue(guidance.showsOval)
        XCTAssertEqual(guidance.motion, .grow)
    }

    func testLeaningInFillsTheRingWithNearness() {
        let far = LivenessGuidance(state: .awaitingFaceInOvalMatch(.moveFaceCloser, 0.25))
        let near = LivenessGuidance(state: .awaitingFaceInOvalMatch(.moveFaceCloser, 0.9))

        XCTAssertEqual(far.title, LocalizedStrings.guidance_lean_in_title)
        XCTAssertLessThan(far.progress, near.progress)
        XCTAssertLessThan(near.progress, 1)
    }

    func testOffCenterFacesAreGuidedByTheOvalNotByHeadTurns() {
        for reason in [LivenessStateMachine.FaceNotPreparedReason.moveFaceLeft, .moveFaceRight, .notInOval] {
            let guidance = LivenessGuidance(state: .awaitingFaceInOvalMatch(reason, 0.5))
            XCTAssertEqual(guidance.title, LocalizedStrings.guidance_lean_in_title, "\(reason)")
        }
    }

    func testTooCloseAsksToMoveBackAsAWarning() {
        let beforeOval = LivenessGuidance(state: .pendingFacePreparedConfirmation(.faceTooClose))
        let duringOval = LivenessGuidance(state: .awaitingFaceInOvalMatch(.faceTooClose, 1))

        XCTAssertEqual(beforeOval, .moveBack(showsOval: false))
        XCTAssertEqual(duringOval, .moveBack(showsOval: true))
        XCTAssertEqual(duringOval.tone, .warning)
        XCTAssertEqual(duringOval.motion, .shrink)
    }

    func testMissingAndExtraFacesAreWarnings() {
        XCTAssertEqual(
            LivenessGuidance(state: .awaitingFaceInOvalMatch(.noFace, 0)),
            .faceMissing(showsOval: true)
        )
        XCTAssertEqual(
            LivenessGuidance(state: .pendingFacePreparedConfirmation(.multipleFaces)),
            .onlyOneFace(showsOval: false)
        )
    }

    func testAMatchAsksToHoldStillWithAFullRing() {
        let guidance = LivenessGuidance(state: .faceMatched)

        XCTAssertEqual(guidance, .holdStill)
        XCTAssertEqual(guidance.progress, 1)
        XCTAssertEqual(guidance.tone, .success)
    }

    func testFinishingShowsTheCompletionMark() {
        for state in [LivenessStateMachine.State.completedNoLightCheck, .completed] {
            XCTAssertTrue(LivenessGuidance(state: state).isComplete, "\(state)")
        }
    }

    func testGrowSweepsOutwardAndShrinkSweepsInward() {
        let start = Date(timeIntervalSinceReferenceDate: 0.1)
        let later = Date(timeIntervalSinceReferenceDate: 1.0)

        XCTAssertLessThan(
            LivenessGuidance.Motion.grow.sweep(at: start, amplitude: 0.2).scale,
            LivenessGuidance.Motion.grow.sweep(at: later, amplitude: 0.2).scale
        )
        XCTAssertGreaterThan(
            LivenessGuidance.Motion.shrink.sweep(at: start, amplitude: 0.2).scale,
            LivenessGuidance.Motion.shrink.sweep(at: later, amplitude: 0.2).scale
        )
        XCTAssertEqual(LivenessGuidance.Motion.still.pulse(at: later, amplitude: 0.2), 1)
    }
}
