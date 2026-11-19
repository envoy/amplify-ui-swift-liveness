import SwiftUI

struct GuidanceMotionFrame {
    let scale: CGFloat
    let opacity: Double
}

extension LivenessGuidance.Motion {
    private static let period: TimeInterval = 1.4

    var isAnimated: Bool {
        self != .still
    }

    func sweep(at date: Date, amplitude: CGFloat) -> GuidanceMotionFrame {
        let phase = date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: Self.period) / Self.period
        let eased = CGFloat(1 - pow(1 - phase, 3))
        let fade = min(1, phase * 4) * min(1, (1 - phase) * 4)

        switch self {
        case .grow:
            return GuidanceMotionFrame(scale: 1 - amplitude * (1 - eased), opacity: fade)
        case .shrink:
            return GuidanceMotionFrame(scale: 1 + amplitude * (1 - eased), opacity: fade)
        case .still:
            return GuidanceMotionFrame(scale: 1, opacity: 0)
        }
    }
}
