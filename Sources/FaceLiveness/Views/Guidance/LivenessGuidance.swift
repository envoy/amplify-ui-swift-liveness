import Foundation

struct LivenessGuidance: Equatable {
    enum Motion: Equatable {
        case still
        case grow
        case shrink
    }

    let title: String
    let detail: String
    let motion: Motion
    let progress: Double
    let showsOval: Bool
    let isMatched: Bool

    private init(
        title: String,
        detail: String,
        motion: Motion = .still,
        progress: Double = 0,
        showsOval: Bool = false,
        isMatched: Bool = false
    ) {
        self.title = title
        self.detail = detail
        self.motion = motion
        self.progress = progress
        self.showsOval = showsOval
        self.isMatched = isMatched
    }

    static let gettingReady = LivenessGuidance(
        title: LocalizedStrings.guidance_getting_ready_title,
        detail: LocalizedStrings.guidance_getting_ready_detail
    )

    static let lookAtCamera = LivenessGuidance(
        title: LocalizedStrings.guidance_look_title,
        detail: LocalizedStrings.guidance_look_detail
    )

    static let holdStill = LivenessGuidance(
        title: LocalizedStrings.guidance_hold_title,
        detail: LocalizedStrings.guidance_hold_detail,
        progress: 1,
        showsOval: true,
        isMatched: true
    )

    static let done = LivenessGuidance(
        title: LocalizedStrings.guidance_done_title,
        detail: LocalizedStrings.guidance_done_detail,
        progress: 1,
        showsOval: true,
        isMatched: true
    )

    static func leanIn(nearness: Double) -> LivenessGuidance {
        LivenessGuidance(
            title: LocalizedStrings.guidance_lean_in_title,
            detail: LocalizedStrings.guidance_lean_in_detail,
            motion: .grow,
            progress: 0.1 + 0.8 * min(max(nearness, 0), 1),
            showsOval: true
        )
    }

    static func moveBack(showsOval: Bool) -> LivenessGuidance {
        LivenessGuidance(
            title: LocalizedStrings.guidance_move_back_title,
            detail: LocalizedStrings.guidance_move_back_detail,
            motion: .shrink,
            showsOval: showsOval
        )
    }

    static func faceMissing(showsOval: Bool) -> LivenessGuidance {
        LivenessGuidance(
            title: LocalizedStrings.guidance_look_title,
            detail: LocalizedStrings.guidance_face_missing_detail,
            showsOval: showsOval
        )
    }

    static func onlyOneFace(showsOval: Bool) -> LivenessGuidance {
        LivenessGuidance(
            title: LocalizedStrings.guidance_one_face_title,
            detail: LocalizedStrings.guidance_one_face_detail,
            showsOval: showsOval
        )
    }

    static func lighting(brighter: Bool, showsOval: Bool) -> LivenessGuidance {
        LivenessGuidance(
            title: brighter
                ? LocalizedStrings.guidance_brighter_title
                : LocalizedStrings.guidance_dimmer_title,
            detail: LocalizedStrings.guidance_lighting_detail,
            showsOval: showsOval
        )
    }
}
