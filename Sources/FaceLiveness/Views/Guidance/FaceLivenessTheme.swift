import SwiftUI
import UIKit

/// What the host app sets on the capture screen so it matches the host's own pages. Everything
/// else on the screen is fixed by the approved design (`LivenessCaptureStyle`).
public struct FaceLivenessTheme: Equatable {
    /// The instruction under the camera, in the host's page title style.
    public var titleFont: UIFont
    public var titleColor: UIColor
    /// The location's colour, which fills the ring round the camera.
    public var accentColor: UIColor
    /// The page behind the camera window; white keeps lighting the visitor's face.
    public var backgroundColor: UIColor
    /// Room the host keeps for its own chrome, such as its top bar and a corner mark; the camera
    /// and the instruction are centred in what is left.
    public var contentInsets: UIEdgeInsets

    public init(
        titleFont: UIFont = UIFont(name: "SofiaProV4-Bold", size: 36) ?? .boldSystemFont(ofSize: 36),
        titleColor: UIColor = UIColor(red: 40 / 255, green: 44 / 255, blue: 54 / 255, alpha: 1),
        accentColor: UIColor = UIColor(red: 233 / 255, green: 28 / 255, blue: 28 / 255, alpha: 1),
        backgroundColor: UIColor = .white,
        contentInsets: UIEdgeInsets = .zero
    ) {
        self.titleFont = titleFont
        self.titleColor = titleColor
        self.accentColor = accentColor
        self.backgroundColor = backgroundColor
        self.contentInsets = contentInsets
    }

    /// The height of one line of the instruction.
    var titleLineHeight: CGFloat {
        titleFont.pointSize * LivenessCaptureStyle.titleLineHeightMultiple
    }
}

private struct FaceLivenessThemeKey: EnvironmentKey {
    static let defaultValue = FaceLivenessTheme()
}

extension EnvironmentValues {
    var livenessTheme: FaceLivenessTheme {
        get { self[FaceLivenessThemeKey.self] }
        set { self[FaceLivenessThemeKey.self] = newValue }
    }
}
