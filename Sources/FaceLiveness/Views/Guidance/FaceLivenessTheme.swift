import SwiftUI
import UIKit

/// What the host app sets on the capture screen: the font of its instruction. Everything else on
/// the screen is fixed by the approved design (`LivenessCaptureStyle`).
public struct FaceLivenessTheme {
    public var titleFont: UIFont

    public init(
        titleFont: UIFont = UIFont(name: "SofiaProV4-SemiBold", size: 44) ?? .boldSystemFont(ofSize: 44)
    ) {
        self.titleFont = titleFont
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
