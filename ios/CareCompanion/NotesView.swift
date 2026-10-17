import SwiftUI

/// "How are you feeling?": a mood tap or a voice note, both answered by Agatha in the conversation.
/// Below: the notes Agatha wrote down and the papers she kept.
struct NotesView: View {
    @EnvironmentObject var model: ChatModel
    @EnvironmentObject var navigator: Navigator
    @State private var noteToDelete: SavedNote?
    @State private var paperToDelete: SavedPaper?
    @State private var paperToShow: SavedPaper?

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

            sectionTitle("My notes")
            if model.notes.isEmpty {
                emptyText("No notes yet. Ask Agatha: \u{201C}Please write down that I felt dizzy.\u{201D}")
            } else {
                ForEach(model.notes.reversed()) { note in noteCard(note) }
            }

            sectionTitle("My papers")
            if model.papers.isEmpty {
                emptyText("No papers kept yet. Show Agatha a letter and she can keep it here for you.")
            } else {
                ForEach(model.papers.reversed()) { paper in paperCard(paper) }
            }
        }
        .alert("Delete this note?", isPresented: isPresent($noteToDelete), presenting: noteToDelete) { note in
            Button("Delete", role: .destructive) { model.deleteNote(note) }
            Button("Keep it", role: .cancel) {}
        } message: { note in
            Text("\u{201C}\(note.title)\u{201D} will be gone for good.")
        }
        .alert("Delete this paper?", isPresented: isPresent($paperToDelete), presenting: paperToDelete) { paper in
            Button("Delete", role: .destructive) { model.deletePaper(paper) }
            Button("Keep it", role: .cancel) {}
        } message: { paper in
            Text("The photo of \u{201C}\(paper.title)\u{201D} will be gone for good.")
        }
        .sheet(item: $paperToShow) { paper in PaperSheet(paper: paper) }
    }

    // MARK: - Notes and papers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typeface.heading(26))
            .foregroundStyle(Theme.Palette.ink)
            .padding(.top, 12)
    }

    private func emptyText(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typeface.body(19))
            .foregroundStyle(Theme.Palette.inkSoft)
            .fixedSize(horizontal: false, vertical: true)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Palette.white, in: RoundedRectangle(cornerRadius: 22))
    }

    private func noteCard(_ note: SavedNote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(note.kindLabel(doctor: model.profile.doctor_name))
                    .font(Theme.Typeface.body(16, weight: .bold))
                    .foregroundStyle(Theme.Palette.purpleDeep)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Theme.Palette.lavender, in: Capsule())
                Spacer(minLength: 8)
                Text(note.date.formatted(date: .abbreviated, time: .shortened))
                    .font(Theme.Typeface.body(16))
                    .foregroundStyle(Theme.Palette.inkMuted)
            }
            Text(note.title)
                .font(Theme.Typeface.body(21, weight: .bold))
                .foregroundStyle(Theme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(note.text)
                .font(Theme.Typeface.body(19))
                .foregroundStyle(Theme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            deleteButton("Delete note") { noteToDelete = note }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.white, in: RoundedRectangle(cornerRadius: 22))
    }

    private func paperCard(_ paper: SavedPaper) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { paperToShow = paper } label: {
                HStack(alignment: .top, spacing: 14) {
                    PaperImage(paper: paper)
                        .frame(width: 84, height: 108)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 6) {
                        Text(paper.title)
                            .font(Theme.Typeface.body(21, weight: .bold))
                            .foregroundStyle(Theme.Palette.ink)
                        Text(paper.summary)
                            .font(Theme.Typeface.body(18))
                            .foregroundStyle(Theme.Palette.ink)
                        Text(paper.date.formatted(date: .abbreviated, time: .omitted))
                            .font(Theme.Typeface.body(16))
                            .foregroundStyle(Theme.Palette.inkMuted)
                        Text("Tap to see the photo")
                            .font(Theme.Typeface.body(16, weight: .bold))
                            .foregroundStyle(Theme.Palette.purpleDeep)
                    }
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(PressableCardStyle())
            .accessibilityLabel("\(paper.title). Tap to see the photo.")
            deleteButton("Delete paper") { paperToDelete = paper }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.white, in: RoundedRectangle(cornerRadius: 22))
    }

    private func deleteButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: "trash")
                .font(Theme.Typeface.body(18, weight: .bold))
                .foregroundStyle(Theme.Palette.sosText)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Theme.Palette.sosSoft, in: Capsule())
        }
        .buttonStyle(PressableCardStyle())
        .padding(.top, 4)
    }

    /// An alert shown while `item` is set; dismissing it clears the item.
    private func isPresent<T>(_ item: Binding<T?>) -> Binding<Bool> {
        Binding(get: { item.wrappedValue != nil }, set: { if !$0 { item.wrappedValue = nil } })
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

/// The kept photo, loaded from the app's Documents folder.
private struct PaperImage: View {
    let paper: SavedPaper

    var body: some View {
        if let image = UIImage(contentsOfFile: paper.fileURL.path(percentEncoded: false)) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            Image(systemName: "doc.text")
                .font(.system(size: 34))
                .foregroundStyle(Theme.Palette.inkMuted)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.Palette.lavender)
        }
    }
}

/// Full photo of a kept paper, with a big Close button.
private struct PaperSheet: View {
    let paper: SavedPaper
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(paper.title)
                .font(Theme.Typeface.heading(26))
                .foregroundStyle(Theme.Palette.ink)
            ScrollView {
                if let image = UIImage(contentsOfFile: paper.fileURL.path(percentEncoded: false)) {
                    Image(uiImage: image).resizable().scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Text("The photo could not be found on this phone.")
                        .font(Theme.Typeface.body(19))
                        .foregroundStyle(Theme.Palette.inkSoft)
                }
            }
            Button("Close") { dismiss() }
                .buttonStyle(PurpleButtonStyle())
        }
        .padding(22)
        .background(Theme.Palette.page.ignoresSafeArea())
    }
}

#Preview {
    NotesView()
        .environmentObject(ChatModel())
        .environmentObject(Navigator())
}
