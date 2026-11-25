import SwiftUI
import UIKit

/// The fixed sizes of the capture screen, from the approved "Face check" design. The
/// colours, the instruction's font and the room kept for the host's chrome come from
/// `FaceLivenessTheme`.
enum LivenessCaptureStyle {
    /// The ring round the camera window: 10 pt wide, with an 18 pt gap to the window.
    static let ringGap: CGFloat = 18
    static let ringWidth: CGFloat = 10
    static let track = Color(red: 235 / 255, green: 235 / 255, blue: 240 / 255)
    /// The window before the camera's first frame.
    static let emptyWindow = Color(red: 228 / 255, green: 230 / 255, blue: 235 / 255)

    /// The instruction sits this far below the ring, at least this far in from the sides.
    static let captionGap: CGFloat = 40
    static let captionInset: CGFloat = 96
    static let titleLineHeightMultiple: CGFloat = 1.15

    /// The camera window is at most this share of the screen's height, and this tall, so it reads
    /// as part of the page in landscape and doesn't tower over it in portrait.
    static let windowHeightShare: CGFloat = 0.58
    static let maximumWindowHeight: CGFloat = 600

    /// The oval assumed until the service sends its own, as fractions of the checked frame; it has
    /// the service's usual proportions, so the window barely changes when the real one arrives.
    static let nominalOval = CGRect(x: 0.2, y: 0.17, width: 0.6, height: 0.6)

    /// The window moving onto the service's oval, in step with the camera image behind it.
    static let windowAnimationDuration: TimeInterval = 0.45
    static var windowAnimation: Animation? {
        UIAccessibility.isReduceMotionEnabled ? nil : .timingCurve(0.45, 0, 0.2, 1, duration: windowAnimationDuration)
    }

    /// How far outside the window the ring's outer edge reaches.
    static var ringOutset: CGFloat {
        ringGap + ringWidth / 2
    }
}
