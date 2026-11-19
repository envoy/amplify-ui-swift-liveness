import SwiftUI

enum LivenessStyle {
    static let background = Color(red: 246 / 255, green: 246 / 255, blue: 249 / 255)
    static let ink = Color(red: 48 / 255, green: 53 / 255, blue: 65 / 255)
    static let secondaryInk = Color(red: 99 / 255, green: 105 / 255, blue: 118 / 255)
    static let track = Color(red: 222 / 255, green: 225 / 255, blue: 231 / 255)
    static let cameraBackdrop = Color(red: 31 / 255, green: 35 / 255, blue: 45 / 255)
    static let success = Color(red: 30 / 255, green: 204 / 255, blue: 106 / 255)
    static let warning = Color(red: 238 / 255, green: 146 / 255, blue: 20 / 255)

    static func title(_ size: CGFloat) -> Font {
        .custom("SofiaPro-Bold", size: size)
    }

    static func body(_ size: CGFloat) -> Font {
        .custom("SofiaProMedium", size: size)
    }
}

extension LivenessGuidance.Tone {
    var color: Color {
        switch self {
        case .guide:
            return LivenessStyle.ink
        case .warning:
            return LivenessStyle.warning
        case .success:
            return LivenessStyle.success
        }
    }
}
