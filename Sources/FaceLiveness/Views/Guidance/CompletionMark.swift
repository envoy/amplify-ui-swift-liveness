import SwiftUI

struct CompletionMark: View {
    let diameter: CGFloat

    var body: some View {
        ZStack {
            LivenessStyle.success.opacity(0.88)

            Image(systemName: "checkmark")
                .font(.system(size: diameter * 0.28, weight: .bold))
                .foregroundColor(.white)
        }
        .transition(.scale(scale: 0.6).combined(with: .opacity))
        .accessibilityHidden(true)
    }
}
