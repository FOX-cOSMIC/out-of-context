import SwiftUI

/// "Need help?": call 112, the family helper or the doctor, or send a help message.
struct SOSView: View {
    @EnvironmentObject var model: ChatModel
    @EnvironmentObject var navigator: Navigator
    @Environment(\.openURL) private var openURL
    @AppStorage("helperPhone") private var helperPhone = ""
    @AppStorage("doctorPhone") private var doctorPhone = ""
    @State private var editing: Contact?

    enum Contact: String, Identifiable {
        case helper, doctor
        var id: String { rawValue }
    }

    var body: some View {
        let p = model.profile
        TabScreen {
            VStack(alignment: .leading, spacing: 6) {
                Text("Need help?")
                    .font(Theme.Typeface.heading(32))
                    .foregroundStyle(Theme.Palette.ink)
                (Text("Tap a button, or just say ") + Text("“Agatha, I need help.”").bold())
                    .font(Theme.Typeface.body(19))
                    .foregroundStyle(Theme.Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // 112
            Button { call("112") } label: {
                HStack(spacing: 18) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 68, height: 68)
                        .background(.white.opacity(0.2), in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Call 112").font(Theme.Typeface.heading(32))
                        Text("Ambulance and emergency").font(Theme.Typeface.body(19, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    Spacer(minLength: 0)
                }
                .padding(20)
                .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
                .background(Theme.Palette.sosRed, in: RoundedRectangle(cornerRadius: 28))
                .shadow(color: Theme.Palette.sosRed.opacity(0.3), radius: 14, y: 8)
            }
            .buttonStyle(PressableCardStyle())
            .accessibilityLabel("Call 112, ambulance and emergency")

            // Family helper
            HelpCard(
                title: p.helper_name.isEmpty ? "Call my family helper" : "Call \(p.helper_name)",
                subtitle: p.helper_relation.isEmpty ? (helperPhone.isEmpty ? "Tap to add the number" : "My family") : p.helper_relation,
                background: Theme.Palette.lavender,
                icon: {
                    Group {
                        if let initial = p.helper_name.first {
                            Text(String(initial).uppercased()).font(Theme.Typeface.heading(26))
                        } else {
                            Image(systemName: "person.fill").font(.system(size: 26, weight: .semibold))
                        }
                    }
                    .foregroundStyle(Theme.Palette.ink)
                    .frame(width: 60, height: 60)
                    .background(Theme.Palette.pink, in: Circle())
                },
                action: { helperPhone.isEmpty ? (editing = .helper) : call(helperPhone) },
                onLongPress: { editing = .helper }
            )

            // Doctor
            HelpCard(
                title: p.doctor_name.isEmpty ? "Call my doctor" : "Call Dr. \(p.doctor_name)",
                subtitle: "My family doctor",
                background: Theme.Palette.mint,
                icon: {
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Theme.Palette.green)
                        .frame(width: 60, height: 60)
                        .background(Theme.Palette.white, in: Circle())
                },
                action: { doctorPhone.isEmpty ? (editing = .doctor) : call(doctorPhone) },
                onLongPress: { editing = .doctor }
            )

            // Help message
            ShareLink(item: helpMessage) {
                HelpCardLabel(
                    title: "Send a help message",
                    subtitle: "To my family",
                    background: Theme.Palette.peach
                ) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Theme.Palette.orangeText)
                        .frame(width: 60, height: 60)
                        .background(Theme.Palette.white, in: Circle())
                }
            }
            .buttonStyle(PressableCardStyle())

            if !helperPhone.isEmpty || !doctorPhone.isEmpty {
                Text("Press and hold a card to change its phone number.")
                    .font(Theme.Typeface.body(17))
                    .foregroundStyle(Theme.Palette.inkSoft)
            }
        }
        .sheet(item: $editing) { contact in
            PhoneNumberSheet(
                title: contact == .helper ? "Phone number of your helper" : "Phone number of your doctor",
                number: contact == .helper ? helperPhone : doctorPhone
            ) { number in
                if contact == .helper { helperPhone = number } else { doctorPhone = number }
                editing = nil
                call(number)
            }
            .presentationDetents([.medium])
        }
    }

    private var helpMessage: String {
        let name = model.profile.name.isEmpty ? "" : " This is \(model.profile.name)."
        return "I need help. Please call me.\(name)"
    }

    private func call(_ number: String) {
        let digits = number.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty, let url = URL(string: "tel://\(digits)") else { return }
        openURL(url)
    }
}

// MARK: - Pieces

private struct HelpCardLabel<Icon: View>: View {
    let title: String
    let subtitle: String
    let background: Color
    @ViewBuilder var icon: Icon

    var body: some View {
        HStack(spacing: 18) {
            icon
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typeface.body(22, weight: .bold))
                    .foregroundStyle(Theme.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(Theme.Typeface.body(18))
                    .foregroundStyle(Theme.Palette.inkMuted)
            }
            .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background(background, in: RoundedRectangle(cornerRadius: 24))
    }
}

private struct HelpCard<Icon: View>: View {
    let title: String
    let subtitle: String
    let background: Color
    @ViewBuilder var icon: Icon
    let action: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        Button(action: action) {
            HelpCardLabel(title: title, subtitle: subtitle, background: background) { icon }
        }
        .buttonStyle(PressableCardStyle())
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.8).onEnded { _ in onLongPress() })
        .accessibilityAction(named: "Change phone number", onLongPress)
    }
}

private struct PhoneNumberSheet: View {
    let title: String
    @State var number: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(Theme.Typeface.heading(26))
                .foregroundStyle(Theme.Palette.ink)
            TextField("Phone number", text: $number)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .font(Theme.Typeface.body(28, weight: .semibold))
                .padding(.horizontal, 18)
                .frame(minHeight: 68)
                .background(Theme.Palette.white, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.Palette.lavenderBorder, lineWidth: 2))
                .focused($focused)
            Button("Save and call") { onSave(number) }
                .buttonStyle(PurpleButtonStyle())
                .disabled(number.filter(\.isNumber).isEmpty)
            Button("Cancel") { dismiss() }
                .font(Theme.Typeface.body(20, weight: .semibold))
                .foregroundStyle(Theme.Palette.inkSoft)
                .frame(maxWidth: .infinity, minHeight: 56)
        }
        .padding(24)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Theme.Palette.page.ignoresSafeArea())
        .onAppear { focused = true }
    }
}

#Preview {
    SOSView()
        .environmentObject(ChatModel())
        .environmentObject(Navigator())
}
