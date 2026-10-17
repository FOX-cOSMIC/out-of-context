import SwiftUI

/// Agatha, the friendly robot from the design (glasses, antenna with an orange ball,
/// purple vest with an orange bow tie). Vector art in Assets.xcassets/AgathaMascot.
struct AgathaMascot: View {
    var size: CGFloat

    var body: some View {
        Image("AgathaMascot")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// The mascot sitting in a white circle with soft lavender rings around it.
struct MascotBadge: View {
    var circle: CGFloat
    var ringColor: Color = Theme.Colors.heroRing
    var showRings = true

    var body: some View {
        ZStack {
            if showRings {
                Circle().stroke(ringColor, lineWidth: 2).frame(width: circle * 1.36, height: circle * 1.36)
                Circle().fill(ringColor.opacity(0.5)).frame(width: circle * 1.18, height: circle * 1.18)
            }
            Circle()
                .fill(Theme.Palette.white)
                .frame(width: circle, height: circle)
                .shadow(color: Theme.Colors.shadow, radius: circle * 0.08, y: circle * 0.04)
            AgathaMascot(size: circle * 0.78)
        }
    }
}

#Preview {
    MascotBadge(circle: Theme.Metrics.mascotCircle)
        .padding(60)
        .background(Theme.Colors.hero)
}
