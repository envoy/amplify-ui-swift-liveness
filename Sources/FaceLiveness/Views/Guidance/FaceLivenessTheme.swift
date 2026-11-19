import SwiftUI
import UIKit

public struct FaceLivenessTheme {
    public var accent: UIColor
    public var success: UIColor
    public var background: UIColor
    public var ink: UIColor
    public var secondaryInk: UIColor
    public var track: UIColor
    public var titleFont: UIFont
    public var bodyFont: UIFont

    public init(
        accent: UIColor = UIColor(red: 97 / 255, green: 97 / 255, blue: 255 / 255, alpha: 1),
        success: UIColor = UIColor(red: 33 / 255, green: 148 / 255, blue: 78 / 255, alpha: 1),
        background: UIColor = UIColor(red: 246 / 255, green: 246 / 255, blue: 249 / 255, alpha: 1),
        ink: UIColor = UIColor(red: 40 / 255, green: 44 / 255, blue: 54 / 255, alpha: 1),
        secondaryInk: UIColor = UIColor(red: 40 / 255, green: 44 / 255, blue: 54 / 255, alpha: 0.6),
        track: UIColor = UIColor(red: 201 / 255, green: 203 / 255, blue: 212 / 255, alpha: 1),
        titleFont: UIFont = UIFont(name: "SofiaPro-Bold", size: 36) ?? .boldSystemFont(ofSize: 36),
        bodyFont: UIFont = UIFont(name: "SofiaProRegular", size: 22) ?? .systemFont(ofSize: 22)
    ) {
        self.accent = accent
        self.success = success
        self.background = background
        self.ink = ink
        self.secondaryInk = secondaryInk
        self.track = track
        self.titleFont = titleFont
        self.bodyFont = bodyFont
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
