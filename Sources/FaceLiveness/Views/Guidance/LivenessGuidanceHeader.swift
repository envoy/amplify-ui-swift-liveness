import SwiftUI

struct LivenessGuidanceHeader: View {
    let guidance: LivenessGuidance

    var body: some View {
        VStack(spacing: 20) {
            GuidanceBadge(guidance: guidance)

            VStack(spacing: 10) {
                Text(guidance.title)
                    .font(LivenessStyle.title(52))
                    .foregroundColor(LivenessStyle.ink)

                Text(guidance.detail)
                    .font(LivenessStyle.body(26))
                    .foregroundColor(LivenessStyle.secondaryInk)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

private struct GuidanceBadge: View {
    let guidance: LivenessGuidance

    var body: some View {
        TimelineView(.animation(paused: !guidance.motion.isAnimated)) { context in
            Image(systemName: guidance.symbol)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(guidance.motion.pulse(at: context.date, amplitude: 0.12))
                .frame(width: 84, height: 84)
                .background(Circle().fill(guidance.tone.color))
                .shadow(color: guidance.tone.color.opacity(0.35), radius: 14, y: 8)
        }
        .accessibilityHidden(true)
    }
}
