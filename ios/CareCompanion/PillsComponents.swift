import SwiftUI

// Small building blocks shared by the Pills, Scan, SOS and Notes screens (Valentina's design).

/// Title + subtitle at the top of a tab screen.
struct ScreenHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Theme.Typeface.heading(32))
                .foregroundStyle(Theme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle {
                Text(subtitle)
                    .font(Theme.Typeface.body(19))
                    .foregroundStyle(Theme.Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Scrollable page with the design's background and room for the tab bar drawn by RootView.
struct TabScreen<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) { content }
                .padding(.horizontal, 22)
                .padding(.top, 24)
                .padding(.bottom, 110)
        }
        .background(Theme.Palette.page.ignoresSafeArea())
    }
}

/// White rounded square holding an icon, as on the design's cards.
struct IconTile: View {
    let systemName: String
    var color: Color = Theme.Palette.ink
    var background: Color = Theme.Palette.white
    var circle = false

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 26, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 60, height: 60)
            .background(background, in: RoundedRectangle(cornerRadius: circle ? 30 : 16))
    }
}

/// The big purple pill-shaped button.
struct PurpleButtonStyle: ButtonStyle {
    var color: Color = Theme.Palette.purple

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typeface.heading(21))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 60)
            .padding(.horizontal, 16)
            .background(color, in: Capsule())
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

/// A card that shrinks a little while pressed.
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
