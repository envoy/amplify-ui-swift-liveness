import Foundation

extension LivenessGuidance {
    init(state: LivenessStateMachine.State) {
        switch state {
        case .pendingFacePreparedConfirmation(let reason):
            self = .correcting(reason, nearness: 0, showsOval: false)
        case .recording(ovalDisplayed: true):
            self = .leanIn(nearness: 0)
        case .awaitingFaceInOvalMatch(let reason, let nearness):
            self = .correcting(reason, nearness: nearness, showsOval: true)
        case .faceMatched, .displayingFreshness:
            self = .holdStill
        case .completedNoLightCheck, .completedDisplayingFreshness, .completed,
             .awaitingDisconnectEvent, .disconnectEventReceived:
            self = .done
        default:
            self = .lookAtCamera
        }
    }

    private static func correcting(
        _ reason: LivenessStateMachine.FaceNotPreparedReason,
        nearness: Double,
        showsOval: Bool
    ) -> LivenessGuidance {
        switch reason {
        case .pendingCheck, .notInOval, .moveFaceCloser, .moveFaceLeft, .moveFaceRight:
            return showsOval ? .leanIn(nearness: nearness) : .lookAtCamera
        case .faceTooClose:
            return .moveBack(showsOval: showsOval)
        case .noFace:
            return .faceMissing(showsOval: showsOval)
        case .multipleFaces:
            return .onlyOneFace(showsOval: showsOval)
        case .moveToBrighterArea:
            return .lighting(brighter: true, showsOval: showsOval)
        case .moveToDimmerArea:
            return .lighting(brighter: false, showsOval: showsOval)
        }
    }
}
