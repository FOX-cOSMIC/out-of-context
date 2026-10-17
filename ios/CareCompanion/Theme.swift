import SwiftUI

// Change the design here.
//
// Every colour, font, size, corner radius and spacing the screens use lives in this file.
// The views only refer to these names (Theme.Colors.accent, Theme.Fonts.message, ...),
// so a new look means editing the values below, not hunting through the views.
// The values today are Apple's system colours and text styles, so Dark Mode and
// larger text sizes keep working automatically.

enum Theme {

    // MARK: - Colours

    enum Colors {
        /// Behind everything (the screen itself).
        static let background = Color(.systemGroupedBackground)
        /// Cards, Agatha's speech bubbles, the welcome card and the typing field.
        static let surface = Color(.secondarySystemGroupedBackground)
        /// The translucent strip behind the skills bar (top) and the buttons (bottom).
        static let bar: Material = .bar

        /// Main brand colour: the Talk button, links, "Take" buttons, card outlines.
        static let accent = Color.accentColor
        /// The user's own speech bubbles.
        static let userBubble = Color.accentColor.opacity(0.15)
        /// The live bubble while the user is still talking (words appear as Agatha hears them).
        static let liveBubble = Color.accentColor.opacity(0.08)
        /// Dashed outline around the live bubble.
        static let liveBubbleBorder = Color.accentColor.opacity(0.5)
        /// The small "Listening…" label and dot above the live bubble.
        static let liveIndicator = Color.red
        /// Thin outline around Agatha's cards.
        static let cardBorder = Color.accentColor.opacity(0.3)
        /// Background of a "Take" button that is not ticked yet.
        static let takeButtonBackground = Color.accentColor.opacity(0.12)

        /// The big green "Start" button on first launch.
        static let callGreen = Color.green
        /// Recording (Talk button while listening, "Listening…" text) and "End call".
        static let danger = Color.red
        /// The "Show me a photo" button.
        static let photoButton = Color.indigo
        /// Done / taken / saved / "Yes, right" / a newly learned skill.
        static let success = Color.green
        /// The "No" button on a "Here is what I read" card.
        static let neutralButton = Color.gray
        /// Background of the "I could not read everything" box.
        static let warningBackground = Color.orange.opacity(0.15)
        /// Text and icons placed on a coloured button.
        static let onColor = Color.white

        /// Normal text. Hierarchical style, so it picks up vibrancy on the translucent bars.
        static let textPrimary = HierarchicalShapeStyle.primary
        /// Quieter text: hints, explanations, things not done yet.
        static let textSecondary = HierarchicalShapeStyle.secondary
        /// Same two text colours as plain Colors, for places that switch between
        /// a colour and normal text (for example red while recording, otherwise normal).
        static let textPrimaryColor = Color.primary
        static let textSecondaryColor = Color.secondary
    }

    // MARK: - Fonts

    enum Fonts {
        /// "Hello! I'm Agatha." on the welcome card.
        static let welcomeTitle = Font.title.bold()
        /// Message text in bubbles, the welcome text, the typing field, "Thinking…".
        static let message = Font.title3
        /// "Listening…" / "Thinking…" while a call is on.
        static let callStatus = Font.title3.weight(.bold)
        /// The small "Listening…" label above the live bubble.
        static let liveIndicator = Font.callout.weight(.semibold)
        /// Status line under the bubbles when no call is on.
        static let status = Font.title3.weight(.semibold)
        /// Small hints such as "Tap Start to begin" and "AI can make mistakes".
        static let hint = Font.callout
        /// Short bold labels: toolbar "Call" and "Done", "Take" buttons, section headers.
        static let headline = Font.headline
        /// Label on the big coloured buttons ("Show me a photo", "End call", "Yes, right").
        static let buttonLabel = Font.title2.weight(.bold)

        /// Card headings: "Morning", "Here is what I read".
        static let cardTitle = Font.title2.bold()
        /// One line item inside a card: medicine name, appointment title, "Saved".
        static let itemTitle = Font.title3.bold()
        /// Explanation under a medicine name.
        static let cardBody = Font.body

        /// Skill icons in the skills bar.
        static let skillIcon = Font.title2
        /// Skill names under the icons.
        static let caption = Font.caption
        /// "New skill: …! 🎉"
        static let celebration = Font.subheadline.weight(.semibold)

        /// Settings gear in the top bar.
        static let toolbarIcon = Font.title3
        /// "Read it again" speaker icon next to Agatha's bubbles.
        static let repeatIcon = Font.title2
        /// Round send arrow next to the typing field.
        static let sendIcon = Font.system(size: 40)

        /// Microphone / phone icon inside the big round Talk and Start buttons.
        static let talkIcon = Font.system(size: 54, weight: .bold)
        /// "Tap to talk" text inside the Talk button.
        static let talkLabel = Font.title2.weight(.bold)
        /// "Start" text inside the Start button.
        static let startLabel = Font.largeTitle.weight(.bold)
    }

    // MARK: - Sizes, corners and spacing

    enum Metrics {
        // Corner radii
        /// Bubbles, cards, the welcome card and the big buttons.
        static let cornerLarge: CGFloat = 18
        /// Typing field and photo thumbnails.
        static let cornerMedium: CGFloat = 14
        /// The small "could not read everything" box.
        static let cornerSmall: CGFloat = 12
        /// Outline width around cards.
        static let cardBorderWidth: CGFloat = 2
        /// Outline width and dash length around the live bubble.
        static let liveBubbleBorderWidth: CGFloat = 1.5
        static let liveBubbleDash: CGFloat = 6
        /// The live bubble's text is slightly faded until the user has finished.
        static let liveTextOpacity: Double = 0.75

        // Padding
        /// Space around the screen edges, inside the bottom bar and inside cards.
        static let screenPadding: CGFloat = 16
        /// Inside the welcome card.
        static let welcomePadding: CGFloat = 18
        /// Inside a speech bubble.
        static let bubblePadding: CGFloat = 14
        /// Inside the typing field and the warning box.
        static let fieldPadding: CGFloat = 12
        /// Top and bottom of the skills bar.
        static let skillsBarVerticalPadding: CGFloat = 10
        /// Lines up the "Read it again" icon with the first line of the bubble.
        static let repeatIconTopPadding: CGFloat = 12
        /// Inside the "Take" capsule buttons.
        static let takeButtonHorizontalPadding: CGFloat = 12
        static let takeButtonVerticalPadding: CGFloat = 10
        /// Above and below each medicine row on a schedule card.
        static let scheduleRowPadding: CGFloat = 4
        /// Left and right inside the "End call" button.
        static let endCallHorizontalPadding: CGFloat = 16

        // Spacing between stacked items (smallest to largest)
        static let spacingTiny: CGFloat = 2
        static let spacingXSmall: CGFloat = 4
        static let spacingSmall: CGFloat = 6
        static let spacingMedium: CGFloat = 8
        static let spacingRegular: CGFloat = 10
        static let spacingLarge: CGFloat = 12
        /// Between messages in the conversation.
        static let messageSpacing: CGFloat = 16

        // Buttons and images
        /// Height of the big buttons in the bottom bar ("Show me a photo", "End call").
        static let bigButtonHeight: CGFloat = 52
        /// Height of the "Yes, right" / "No" buttons on a card.
        static let confirmButtonHeight: CGFloat = 56
        /// Tallest a photo the user sent may be in the conversation.
        static let photoMaxHeight: CGFloat = 220

        // The big round Talk and Start buttons
        /// Diameter. Still clearly the biggest thing on screen, but leaves room for the conversation.
        static let talkButtonSize: CGFloat = 190
        /// Gap between the pulsing outer ring and the solid inner circle.
        static let talkRingInset: CGFloat = 14
        static let talkShadowRadius: CGFloat = 8
        static let talkShadowY: CGFloat = 4
        /// Opacity of the pulsing outer ring.
        static let talkRingOpacity: Double = 0.25
        /// The ring grows and shrinks between these two scales.
        static let pulseMaxScale: CGFloat = 1.12
        static let pulseMinScale: CGFloat = 0.96
        /// Seconds for one grow (or shrink) of the ring.
        static let pulseDuration: Double = 1.1

        // Pressed / disabled looks
        /// Talk button while Agatha is busy.
        static let busyOpacity: Double = 0.5
        /// Big coloured button while pressed.
        static let pressedOpacity: Double = 0.75
        /// Big coloured button while disabled.
        static let disabledOpacity: Double = 0.4
    }
}

// MARK: - Valentina's design (Medication Voice Assistant.html)
// Shared by all screens. Builders map the older Theme.Colors / Theme.Fonts tokens onto these.

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

extension Theme {
    enum Palette {
        static let page = Color(hex: 0xFAF9F5)          // warm off-white screen background
        static let white = Color.white
        static let ink = Color(hex: 0x1E1B2E)           // main text
        static let inkSoft = Color(hex: 0x5A5470)       // secondary text
        static let inkMuted = Color(hex: 0x4A4460)
        static let purple = Color(hex: 0x6B3FE0)        // primary: Talk button, main buttons
        static let purpleDark = Color(hex: 0x5B33C9)
        static let purpleDeep = Color(hex: 0x3E1F99)
        static let lavender = Color(hex: 0xEFE6FF)      // hero background, soft cards
        static let lavenderLight = Color(hex: 0xF3EEFB)
        static let lavenderBorder = Color(hex: 0xDDD0F5)
        static let lavenderRing = Color(hex: 0xCDB8FF)
        static let orange = Color(hex: 0xFF7A3D)        // "due now" accents, pills
        static let orangeDark = Color(hex: 0xE0602A)
        static let orangeText = Color(hex: 0xA3400F)
        static let peach = Color(hex: 0xFFF1E3)         // afternoon card, reminder card
        static let mint = Color(hex: 0xE3F6F1)          // taken / morning card, doctor
        static let green = Color(hex: 0x17694B)         // "Taken at 8:02"
        static let yellow = Color(hex: 0xFFB547)
        static let pink = Color(hex: 0xFF9FB2)
        static let sosRed = Color(hex: 0xC8283A)        // "Call 112"
        static let sosSoft = Color(hex: 0xFDECEE)       // SOS tab background
        static let sosText = Color(hex: 0xB3202F)
    }

    /// Quicksand for headings, Atkinson Hyperlegible for everything else (falls back to system fonts).
    enum Typeface {
        static func heading(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
            .custom("Quicksand", size: size, relativeTo: .title).weight(weight)
        }
        static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .custom("Atkinson Hyperlegible", size: size, relativeTo: .body).weight(weight)
        }
    }
}
