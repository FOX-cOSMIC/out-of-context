import SwiftUI

// Change the design here.
//
// Every colour, font, size, corner radius and spacing the screens use lives in this file.
// The views only refer to these names (Theme.Colors.accent, Theme.Fonts.message, ...),
// so a new look means editing the values below, not hunting through the views.
// The values map onto Valentina's design (Theme.Palette / Theme.Typeface at the bottom).
// The palette is light-only, so the app pins the light colour scheme; fonts scale with Dynamic Type.

enum Theme {

    // MARK: - Colours

    enum Colors {
        /// Behind everything (the screen itself).
        static let background = Palette.page
        /// Cards, Agatha's speech bubbles, the welcome card and the typing field.
        static let surface = Palette.white
        /// The strip behind the skills bar (top) and the controls (bottom).
        static let bar = Palette.page
        /// Lavender hero behind the mascot on the Talk screen.
        static let hero = Palette.lavender
        /// Soft rings around the mascot circle.
        static let heroRing = Palette.white.opacity(0.55)

        /// Main brand colour: the Talk button, links, "Take" buttons, card outlines.
        static let accent = Palette.purple
        /// The user's own speech bubbles.
        static let userBubble = Palette.lavender
        /// The live bubble while the user is still talking (words appear as Agatha hears them).
        static let liveBubble = Palette.lavenderLight
        /// Dashed outline around the live bubble.
        static let liveBubbleBorder = Palette.lavenderRing
        /// The small "Listening…" label and dot above the live bubble.
        static let liveIndicator = Palette.sosRed
        /// Thin outline around Agatha's cards.
        static let cardBorder = Palette.lavenderBorder
        /// Background of a "Take" button that is not ticked yet.
        static let takeButtonBackground = Palette.white
        /// Soft shadow under Agatha's bubbles and cards.
        static let shadow = Palette.purpleDeep.opacity(0.10)

        /// The big "Start" button on first launch.
        static let callGreen = Palette.purple
        /// Recording (mascot ring while listening, "Listening…" text) and "End call".
        static let danger = Palette.sosRed
        /// The "Show me a photo" button.
        static let photoButton = Palette.orangeDark
        /// Done / taken / saved / "Yes, right" / a newly learned skill.
        static let success = Palette.green
        /// The "No" button on a "Here is what I read" card.
        static let neutralButton = Palette.inkSoft
        /// Background of the "I could not read everything" box.
        static let warningBackground = Palette.peach
        /// Text and icons placed on a coloured button.
        static let onColor = Color.white

        /// Normal text.
        static let textPrimary = Palette.ink
        /// Quieter text: hints, explanations, things not done yet.
        static let textSecondary = Palette.inkSoft
        /// Same two text colours, for places that switch between a colour and normal text.
        static let textPrimaryColor = Palette.ink
        static let textSecondaryColor = Palette.inkSoft

        /// Schedule card backgrounds per time of day.
        static func slotBackground(_ slot: Slot) -> Color {
            switch slot {
            case .morning: Palette.mint
            case .midday: Palette.peach
            case .evening: Palette.lavender
            case .night: Palette.lavenderLight
            }
        }
    }

    // MARK: - Fonts

    enum Fonts {
        /// "Hello! I'm Agatha." on the welcome card.
        static let welcomeTitle = Typeface.heading(30)
        /// "How are you doing today?" under the mascot.
        static let heroTitle = Typeface.heading(32)
        /// "Hello Agatha!" above the hero title.
        static let heroGreeting = Typeface.body(21)
        /// "MEDICINE HELPER" chip.
        static let chip = Typeface.heading(15)
        /// Message text in bubbles, the welcome text, the typing field, "Thinking…".
        static let message = Typeface.body(21)
        /// "Listening…" / "Thinking…" while a call is on.
        static let callStatus = Typeface.heading(21)
        /// The small "Listening…" label above the live bubble.
        static let liveIndicator = Typeface.body(16, weight: .bold)
        /// Status line under the bubbles when no call is on.
        static let status = Typeface.body(19, weight: .bold)
        /// Small hints such as "Tap Start to begin" and "AI can make mistakes".
        static let hint = Typeface.body(18)
        /// Short bold labels: "Take" buttons, section headers.
        static let headline = Typeface.body(18, weight: .bold)
        /// Label on the big coloured buttons ("Show me a photo", "End call", "Yes, right").
        static let buttonLabel = Typeface.heading(21)

        /// Card headings: "Morning", "Here is what I read".
        static let cardTitle = Typeface.heading(24)
        /// One line item inside a card: medicine name, appointment title, "Saved".
        static let itemTitle = Typeface.body(20, weight: .bold)
        /// Explanation under a medicine name.
        static let cardBody = Typeface.body(17)

        /// Skill icons in the skills bar.
        static let skillIcon = Font.system(size: 18, weight: .semibold)
        /// Skill names under the icons.
        static let caption = Typeface.body(13, weight: .bold)
        /// "New skill: …! 🎉"
        static let celebration = Typeface.body(16, weight: .bold)

        /// Settings gear in the top bar.
        static let toolbarIcon = Font.system(size: 22, weight: .semibold)
        /// "Read it again" speaker icon next to Agatha's bubbles.
        static let repeatIcon = Font.system(size: 22, weight: .semibold)
        /// Round send arrow next to the typing field.
        static let sendIcon = Font.system(size: 44)

        /// Microphone / phone icon inside the big round Start button.
        static let talkIcon = Font.system(size: 54, weight: .bold)
        /// "Tap to talk" / "I'm listening" label under the mascot.
        static let talkLabel = Typeface.heading(22)
        /// "Start" text inside the Start button.
        static let startLabel = Typeface.heading(34)
        /// Labels under the bottom bar icons.
        static let tabLabel = Typeface.body(15, weight: .bold)
        /// Icons in the bottom bar.
        static let tabIcon = Font.system(size: 24, weight: .semibold)
    }

    // MARK: - Sizes, corners and spacing

    enum Metrics {
        // Corner radii
        /// Bubbles, cards, the welcome card and the big buttons.
        static let cornerLarge: CGFloat = 22
        /// Typing field and photo thumbnails.
        static let cornerMedium: CGFloat = 16
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
        static let bigButtonHeight: CGFloat = 56
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

        // Talk screen hero and bottom bar
        /// White circle the mascot sits in (full hero / small header while chatting).
        static let mascotCircle: CGFloat = 220
        static let mascotCircleSmall: CGFloat = 76
        /// Height of the bottom bar's items and the raised Talk button.
        static let tabItemHeight: CGFloat = 60
        static let tabTalkSize: CGFloat = 68
        static let tabBarCorner: CGFloat = 30
        /// Smallest touch target anywhere.
        static let minTouch: CGFloat = 48

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
