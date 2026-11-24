import CoreGraphics
import Foundation

/// What the capture screen is asking the visitor to do: one instruction, and how the guides on
/// the camera show it. Each case is one screen of the approved "Face check guidance" design.
enum LivenessCaptureStep: Equatable {
    /// A face is in view and the service is about to draw its oval: hold still for it.
    case faceFound
    /// No face in view.
    case stepIn
    /// The face is off to one side; `towardRight` is the way to move on screen (the preview is
    /// mirrored, so it is also the visitor's own right).
    case moveToSide(towardRight: Bool)
    /// The oval is up and the face has to grow into it; `progress` fills the ring (0...1).
    case fillOval(progress: Double)
    case moveBack
    case onlyOnePerson
    case tooDark
    case tooBright
    /// The face fills the oval; the ring completes and turns green.
    case holdStill

    /// The one line shown at the bottom of the screen.
    var title: String {
        switch self {
        case .faceFound:
            LocalizedStrings.guidance_hold_title
        case .stepIn:
            LocalizedStrings.guidance_step_in_title
        case .moveToSide(let towardRight):
            towardRight ? LocalizedStrings.guidance_move_right_title : LocalizedStrings.guidance_move_left_title
        case .fillOval:
            LocalizedStrings.guidance_fill_oval_title
        case .moveBack:
            LocalizedStrings.guidance_move_back_title
        case .onlyOnePerson:
            LocalizedStrings.guidance_one_person_title
        case .tooDark:
            LocalizedStrings.guidance_too_dark_title
        case .tooBright:
            LocalizedStrings.guidance_too_bright_title
        case .holdStill:
            LocalizedStrings.guidance_hold_title
        }
    }

    /// How full the ring around the oval is.
    var ringProgress: Double {
        switch self {
        case .fillOval(let progress):
            progress
        case .holdStill:
            1
        default:
            0
        }
    }

    /// Steps that change what the guides draw, ignoring the ring's progress, so loops restart
    /// only when the guidance itself changes.
    var kind: String {
        switch self {
        case .fillOval:
            "fillOval"
        case .moveToSide(let towardRight):
            "moveToSide\(towardRight)"
        default:
            String(describing: self)
        }
    }
}

extension LivenessCaptureStep {
    /// The step for a state of the check, before the face's position is taken into account.
    init(state: LivenessStateMachine.State) {
        switch state {
        case .pendingFacePreparedConfirmation(let reason):
            self = Self.correcting(reason, nearness: 0, ovalShown: false)
        case .recording(ovalDisplayed: true):
            self = .fillOval(progress: Self.ringProgress(nearness: 0))
        case .awaitingFaceInOvalMatch(let reason, let nearness):
            self = Self.correcting(reason, nearness: nearness, ovalShown: true)
        case .faceMatched, .displayingFreshness, .completedNoLightCheck, .completedDisplayingFreshness,
             .completed, .awaitingDisconnectEvent, .disconnectEventReceived:
            self = .holdStill
        default:
            self = .faceFound
        }
    }

    /// The ring starts a tenth full, so it reads as a ring to fill, and stops short of full until
    /// the face actually matches.
    static func ringProgress(nearness: Double) -> Double {
        0.1 + 0.8 * min(max(nearness, 0), 1)
    }

    private static func correcting(
        _ reason: LivenessStateMachine.FaceNotPreparedReason,
        nearness: Double,
        ovalShown: Bool
    ) -> LivenessCaptureStep {
        switch reason {
        case .pendingCheck, .notInOval, .moveFaceCloser, .moveFaceLeft, .moveFaceRight:
            ovalShown ? .fillOval(progress: ringProgress(nearness: nearness)) : .faceFound
        case .faceTooClose:
            .moveBack
        case .noFace:
            .stepIn
        case .multipleFaces:
            .onlyOnePerson
        case .moveToBrighterArea:
            .tooDark
        case .moveToDimmerArea:
            .tooBright
        }
    }

    /// Amazon's oval check calls a face "too close" whenever it runs past the oval's top or bottom,
    /// which also happens to a face that is small enough but sits too high or low (a kiosk tilted
    /// up sees faces high in its frame). So "move back" is only asked for when the face is really
    /// bigger than the oval; otherwise the visitor is still asked to fill it. This changes only the
    /// instruction: whether the face matches is still decided by the service's check.
    func confirmingTooClose(face: CGRect?, oval: CGRect?, nearness: Double) -> LivenessCaptureStep {
        guard self == .moveBack, let oval else { return self }
        guard let face else { return .fillOval(progress: Self.ringProgress(nearness: nearness)) }
        let head = LivenessFaceGuides.headRect(around: face)
        let isBiggerThanOval = head.height > oval.height * 1.05 || head.width > oval.width * 1.05
        return isBiggerThanOval ? self : .fillOval(progress: Self.ringProgress(nearness: nearness))
    }

    /// Swaps in "move to the side" when the face is far enough off centre that leaning in alone
    /// won't line it up. `target` is the oval, or the checked part of the camera before the oval.
    /// Once shown it stays until the face is well back towards the middle, so it doesn't flicker.
    func guidingToSide(face: CGRect?, target: CGRect, wasGuidingToSide: Bool) -> LivenessCaptureStep {
        switch self {
        case .faceFound, .fillOval, .moveToSide:
            break
        default:
            return self
        }
        guard let face, !target.isEmpty else { return self }
        let offset = face.midX - target.midX
        let limit = target.width * (wasGuidingToSide ? 0.32 : 0.45)
        guard abs(offset) > limit else { return self }
        return .moveToSide(towardRight: offset < 0)
    }
}
