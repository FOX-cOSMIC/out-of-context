import SwiftUI

/// "How are you feeling?": a mood tap or a voice note, both answered by Agatha in the conversation.
struct NotesView: View {
    @EnvironmentObject var model: ChatModel
    @EnvironmentObject var navigator: Navigator

    private struct Mood: Identifiable {
        let label: String
        let said: String
        let icon: String
        let color: Color
        let background: Color
        var id: String { label }
    }

    private let moods = [
        Mood(label: "Good", said: "good", icon: "face.smiling", color: Theme.Palette.green, background: Theme.Palette.mint),
        Mood(label: "Okay", said: "okay", icon: "face.dashed", color: Theme.Palette.purple, background: Theme.Palette.lavender),
        Mood(label: "Not well", said: "not well", icon: "cloud.rain", color: Theme.Palette.orangeText, background: Theme.Palette.peach),
    ]

    var body: some View {
        TabScreen {
            ScreenHeader(title: "How are you feeling?",
                         subtitle: "Tell Agatha. She will write it down for your doctor.")

            HStack(spacing: 12) {
                ForEach(moods) { mood in
                    Button { tell(mood) } label: {
                        VStack(spacing: 8) {
                            Image(systemName: mood.icon)
                                .font(.system(size: 34, weight: .medium))
                                .foregroundStyle(mood.color)
                            Text(mood.label)
                                .font(Theme.Typeface.body(19, weight: .bold))
                                .foregroundStyle(Theme.Palette.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, minHeight: 104)
                        .background(mood.background, in: RoundedRectangle(cornerRadius: 22))
                    }
                    .buttonStyle(PressableCardStyle())
                    .accessibilityLabel("I'm feeling \(mood.said)")
                }
            }
            .disabled(!model.canSend)
            .opacity(model.canSend ? 1 : 0.5)

            Button(action: record) {
                HStack(spacing: 18) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 76, height: 76)
                        .background(Theme.Palette.orangeDark, in: Circle())
                        .padding(5)
                        .background(Theme.Palette.white, in: Circle())
                        .shadow(color: Theme.Palette.orange.opacity(0.35), radius: 10, y: 4)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Record a voice note")
                            .font(Theme.Typeface.body(22, weight: .bold))
                            .foregroundStyle(Theme.Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Tap the button and talk")
                            .font(Theme.Typeface.body(18))
                            .foregroundStyle(Theme.Palette.inkMuted)
                    }
                    .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
                .padding(18)
                .frame(maxWidth: .infinity, minHeight: 116, alignment: .leading)
                .background(Theme.Palette.lavender, in: RoundedRectangle(cornerRadius: 24))
            }
            .buttonStyle(PressableCardStyle())
            .disabled(!model.canSend)
            .opacity(model.canSend ? 1 : 0.5)

            Label("Your notes appear in the conversation with Agatha.", systemImage: "text.bubble")
                .font(Theme.Typeface.body(18))
                .foregroundStyle(Theme.Palette.inkSoft)
                .padding(.top, 4)
        }
    }

    private func tell(_ mood: Mood) {
        guard model.canSend else { return }
        navigator.tab = .talk
        Task { await model.send(text: "I'm feeling \(mood.said) today.") }
    }

    private func record() {
        guard model.canSend else { return }
        navigator.tab = .talk
        model.toggleRecording()
    }
}

#Preview {
    NotesView()
        .environmentObject(ChatModel())
        .environmentObject(Navigator())
}
