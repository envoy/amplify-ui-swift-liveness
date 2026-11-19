import Foundation

struct LivenessGuidance: Equatable {
    enum Tone: Equatable {
        case guide
        case warning
        case success
    }

    enum Motion: Equatable {
        case still
        case breathe
        case grow
        case shrink
    }

    let title: String
    let detail: String
    let symbol: String
    let tone: Tone
    let motion: Motion
    let progress: Double
    let showsOval: Bool
    let isComplete: Bool

    private init(
        title: String,
        detail: String,
        symbol: String,
        tone: Tone = .guide,
        motion: Motion = .still,
        progress: Double = 0,
        showsOval: Bool = false,
        isComplete: Bool = false
    ) {
        self.title = title
        self.detail = detail
        self.symbol = symbol
        self.tone = tone
        self.motion = motion
        self.progress = progress
        self.showsOval = showsOval
        self.isComplete = isComplete
    }

    static let gettingReady = LivenessGuidance(
        title: LocalizedStrings.guidance_getting_ready_title,
        detail: LocalizedStrings.guidance_getting_ready_detail,
        symbol: "camera.fill",
        motion: .breathe
    )

    static let lookAtCamera = LivenessGuidance(
        title: LocalizedStrings.guidance_look_title,
        detail: LocalizedStrings.guidance_look_detail,
        symbol: "eye.fill",
        motion: .breathe
    )

    static let holdStill = LivenessGuidance(
        title: LocalizedStrings.guidance_hold_title,
        detail: LocalizedStrings.guidance_hold_detail,
        symbol: "hand.raised.fill",
        tone: .success,
        progress: 1,
        showsOval: true
    )

    static let done = LivenessGuidance(
        title: LocalizedStrings.guidance_done_title,
        detail: LocalizedStrings.guidance_done_detail,
        symbol: "checkmark",
        tone: .success,
        progress: 1,
        showsOval: true,
        isComplete: true
    )

    static func leanIn(nearness: Double) -> LivenessGuidance {
        LivenessGuidance(
            title: LocalizedStrings.guidance_lean_in_title,
            detail: LocalizedStrings.guidance_lean_in_detail,
            symbol: "arrow.up.left.and.arrow.down.right",
            motion: .grow,
            progress: 0.1 + 0.8 * min(max(nearness, 0), 1),
            showsOval: true
        )
    }

    static func moveBack(showsOval: Bool) -> LivenessGuidance {
        LivenessGuidance(
            title: LocalizedStrings.guidance_move_back_title,
            detail: LocalizedStrings.guidance_move_back_detail,
            symbol: "arrow.down.right.and.arrow.up.left",
            tone: .warning,
            motion: .shrink,
            showsOval: showsOval
        )
    }

    static func faceMissing(showsOval: Bool) -> LivenessGuidance {
        LivenessGuidance(
            title: LocalizedStrings.guidance_look_title,
            detail: LocalizedStrings.guidance_face_missing_detail,
            symbol: "eye.fill",
            tone: .warning,
            motion: .breathe,
            showsOval: showsOval
        )
    }

    static func onlyOneFace(showsOval: Bool) -> LivenessGuidance {
        LivenessGuidance(
            title: LocalizedStrings.guidance_one_face_title,
            detail: LocalizedStrings.guidance_one_face_detail,
            symbol: "person.2.fill",
            tone: .warning,
            showsOval: showsOval
        )
    }

    static func lighting(brighter: Bool, showsOval: Bool) -> LivenessGuidance {
        LivenessGuidance(
            title: brighter
                ? LocalizedStrings.guidance_brighter_title
                : LocalizedStrings.guidance_dimmer_title,
            detail: LocalizedStrings.guidance_lighting_detail,
            symbol: brighter ? "sun.max.fill" : "sun.min.fill",
            tone: .warning,
            showsOval: showsOval
        )
    }
}
