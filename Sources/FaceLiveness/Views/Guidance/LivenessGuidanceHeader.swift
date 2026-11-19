import SwiftUI

struct LivenessGuidanceHeader: View {
    @Environment(\.livenessTheme) private var theme
    let guidance: LivenessGuidance

    var body: some View {
        VStack(spacing: 12) {
            Text(guidance.title)
                .font(Font(theme.titleFont as CTFont))
                .foregroundColor(Color(theme.ink))

            Text(guidance.detail)
                .font(Font(theme.bodyFont as CTFont))
                .foregroundColor(Color(theme.secondaryInk))
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }
}
