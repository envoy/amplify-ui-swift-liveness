import SwiftUI
import UIKit

/// The fixed colours and sizes of the capture screen, from the approved "Face check guidance"
/// design. The instruction's font comes from `FaceLivenessTheme`.
enum LivenessCaptureStyle {
    /// The light bar's normal width, and its width when the face is too dark.
    static let lightBarWidth: CGFloat = 34
    static let brightLightBarWidth: CGFloat = 50

    /// The dark tint over the camera outside the oval, and over the whole image before it.
    static let scrim = Color(red: 11 / 255, green: 13 / 255, blue: 18 / 255)
    static let scrimOpacity = 0.5
    static let faceFoundTintOpacity = 0.12
    static let searchTintOpacity = 0.18

    /// The ring's white track, and the green it turns when the face fills the oval.
    static let trackOpacity = 0.32
    static let ringWidth: CGFloat = 6
    static let matched = Color(red: 78 / 255, green: 193 / 255, blue: 118 / 255)

    /// The caption's shade: clear to 78% over the bottom 360 pt.
    static let captionShade = Color(red: 10 / 255, green: 12 / 255, blue: 18 / 255)
    static let captionShadeHeight: CGFloat = 360
    /// The caption sits this far above the light bar, 64 pt in from the sides.
    static let captionGap: CGFloat = 44
    static let captionInset: CGFloat = 64
    /// The instruction's size in the design (the theme's font sets the real one), and its 1.15
    /// line height and -0.01 em tracking.
    static let titleSize: CGFloat = 44
    static let titleLineHeightMultiple: CGFloat = 1.15
    static let titleTracking: CGFloat = -0.01

    /// The chevron and the "Camera" label on the white light bar.
    static let chevronInk = Color(red: 31 / 255, green: 35 / 255, blue: 45 / 255)
    static let labelInk = Color(red: 92 / 255, green: 98 / 255, blue: 112 / 255)

    /// The app's 80 pt back button, translucent dark over the camera, its 14 pt corner concentric
    /// with the camera window's 30 pt corner 16 pt away.
    static let backButtonSize: CGFloat = 80
    static let backButtonInset: CGFloat = 16
    static let backButtonCornerRadius: CGFloat = 14
    static let backButtonFill = Color(red: 12 / 255, green: 14 / 255, blue: 20 / 255).opacity(0.38)
}

public extension View {
    /// Shows the capture screen's back button, which runs `action`. Without it there is none.
    func livenessBackAction(_ action: (() -> Void)?) -> some View {
        environment(\.livenessBackAction, action)
    }
}

/// What the back button does, set by the host; no button is shown without one.
private struct LivenessBackActionKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    var livenessBackAction: (() -> Void)? {
        get { self[LivenessBackActionKey.self] }
        set { self[LivenessBackActionKey.self] = newValue }
    }
}
