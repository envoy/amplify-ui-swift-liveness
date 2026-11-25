import XCTest
import UIKit
@testable import FaceLiveness

final class LivenessGuidanceTests: XCTestCase {
    func testBeforeTheOvalAFoundFaceIsAskedToHoldStill() {
        let states: [LivenessStateMachine.State] = [
            .initial,
            .pendingFacePreparedConfirmation(.pendingCheck),
            .waitForRecording,
            .recording(ovalDisplayed: false)
        ]

        for state in states {
            XCTAssertEqual(LivenessCaptureStep(state: state), .faceFound, "\(state)")
        }
    }

    func testOnceTheOvalIsShownItAsksToFillIt() {
        let step = LivenessCaptureStep(state: .recording(ovalDisplayed: true))

        XCTAssertEqual(step.title, LocalizedStrings.guidance_fill_oval_title)
        XCTAssertGreaterThan(step.ringProgress, 0)
    }

    func testLeaningInFillsTheRingWithNearness() {
        let far = LivenessCaptureStep(state: .awaitingFaceInOvalMatch(.moveFaceCloser, 0.25))
        let near = LivenessCaptureStep(state: .awaitingFaceInOvalMatch(.moveFaceCloser, 0.9))

        XCTAssertLessThan(far.ringProgress, near.ringProgress)
        XCTAssertLessThan(near.ringProgress, 1)
    }

    func testEachProblemHasItsOwnStep() {
        XCTAssertEqual(LivenessCaptureStep(state: .awaitingFaceInOvalMatch(.faceTooClose, 1)), .moveBack)
        XCTAssertEqual(LivenessCaptureStep(state: .pendingFacePreparedConfirmation(.noFace)), .stepIn)
        XCTAssertEqual(LivenessCaptureStep(state: .pendingFacePreparedConfirmation(.multipleFaces)), .onlyOnePerson)
        XCTAssertEqual(LivenessCaptureStep(state: .awaitingFaceInOvalMatch(.moveToBrighterArea, 0)), .tooDark)
        XCTAssertEqual(LivenessCaptureStep(state: .awaitingFaceInOvalMatch(.moveToDimmerArea, 0)), .tooBright)
    }

    func testAMatchAndFinishingHoldStillWithAFullRing() {
        for state in [LivenessStateMachine.State.faceMatched, .completedNoLightCheck, .completed] {
            let step = LivenessCaptureStep(state: state)
            XCTAssertEqual(step, .holdStill, "\(state)")
            XCTAssertEqual(step.ringProgress, 1)
        }
    }

    func testAFaceFarOffCentreIsSentTowardTheMiddle() {
        let oval = CGRect(x: 400, y: 150, width: 360, height: 480)
        let leftOfOval = CGRect(x: 150, y: 300, width: 180, height: 200)
        let rightOfOval = CGRect(x: 830, y: 300, width: 180, height: 200)
        let filling = LivenessCaptureStep.fillOval(progress: 0.4)

        XCTAssertEqual(
            filling.guidingToSide(face: leftOfOval, target: oval, wasGuidingToSide: false),
            .moveToSide(towardRight: true)
        )
        XCTAssertEqual(
            filling.guidingToSide(face: rightOfOval, target: oval, wasGuidingToSide: false),
            .moveToSide(towardRight: false)
        )
    }

    func testSideGuidanceHoldsUntilTheFaceIsWellBack() {
        let oval = CGRect(x: 400, y: 150, width: 360, height: 480)
        // 140 pt left of the oval's centre: inside the 162 pt limit to start, past the 115 pt one to stop.
        let nearlyBack = CGRect(x: 350, y: 300, width: 180, height: 200)
        let filling = LivenessCaptureStep.fillOval(progress: 0.4)

        XCTAssertEqual(filling.guidingToSide(face: nearlyBack, target: oval, wasGuidingToSide: false), filling)
        XCTAssertEqual(
            filling.guidingToSide(face: nearlyBack, target: oval, wasGuidingToSide: true),
            .moveToSide(towardRight: true)
        )
    }

    func testProblemsOtherThanPositionAreNotOverriddenBySideGuidance() {
        let oval = CGRect(x: 400, y: 150, width: 360, height: 480)
        let leftOfOval = CGRect(x: 100, y: 300, width: 180, height: 200)

        XCTAssertEqual(LivenessCaptureStep.moveBack.guidingToSide(face: leftOfOval, target: oval, wasGuidingToSide: false), .moveBack)
        XCTAssertEqual(LivenessCaptureStep.holdStill.guidingToSide(face: leftOfOval, target: oval, wasGuidingToSide: false), .holdStill)
    }

    func testMoveBackOnlyWhenTheFaceIsBiggerThanTheOval() {
        let oval = CGRect(x: 400, y: 150, width: 360, height: 480)
        // A face the right size, but sitting high: Amazon calls it too close, it isn't.
        let highButSmall = CGRect(x: 490, y: 60, width: 180, height: 200)
        let reallyBig = CGRect(x: 380, y: 120, width: 330, height: 380)

        XCTAssertEqual(
            LivenessCaptureStep.moveBack.confirmingTooClose(face: highButSmall, oval: oval, nearness: 0.5),
            .fillOval(progress: LivenessCaptureStep.ringProgress(nearness: 0.5))
        )
        XCTAssertEqual(
            LivenessCaptureStep.moveBack.confirmingTooClose(face: reallyBig, oval: oval, nearness: 0.5),
            .moveBack
        )
        // Before the oval, "move back" comes from the eye spacing and stays.
        XCTAssertEqual(LivenessCaptureStep.moveBack.confirmingTooClose(face: highButSmall, oval: nil, nearness: 0), .moveBack)
    }
}
