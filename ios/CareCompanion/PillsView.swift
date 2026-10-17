import SwiftUI

/// "My pills today": every dose of the day as a card, with a ring showing how many are taken.
struct PillsView: View {
    @EnvironmentObject var model: ChatModel
    @EnvironmentObject var navigator: Navigator

    /// One dose: a medication at one time of day.
    private struct Dose: Identifiable {
        let med: Medication
        let slot: Slot
        var id: String { "\(med.id)|\(slot.rawValue)" }
    }

    private var doses: [Dose] {
        Slot.allCases.flatMap { slot in
            model.plan.medications
                .filter { !$0.times.dose(for: slot).trimmingCharacters(in: .whitespaces).isEmpty }
                .map { Dose(med: $0, slot: slot) }
        }
    }

    var body: some View {
        let doses = doses
        let takenCount = doses.filter { model.isTaken($0.med, slot: $0.slot) }.count
        // The first dose not yet taken is the one "due now"; the others wait for later.
        let dueID = doses.first { !model.isTaken($0.med, slot: $0.slot) }?.id

        TabScreen {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Self.todayText)
                        .font(Theme.Typeface.body(19))
                        .foregroundStyle(Theme.Palette.inkSoft)
                    Text("My pills today")
                        .font(Theme.Typeface.heading(32))
                        .foregroundStyle(Theme.Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                if !doses.isEmpty {
                    ProgressRing(taken: takenCount, total: doses.count)
                }
            }

            if doses.isEmpty {
                emptyState
            } else {
                ForEach(doses) { dose in
                    let taken = model.isTaken(dose.med, slot: dose.slot)
                    DoseCard(
                        med: dose.med,
                        slot: dose.slot,
                        time: time(for: dose.slot),
                        state: taken ? .taken : (dose.id == dueID ? .due : .later),
                        toggle: { withAnimation(.snappy) { model.toggleTaken(dose.med, slot: dose.slot) } }
                    )
                }
                if takenCount == doses.count {
                    Label("All done for today. Well done!", systemImage: "star.fill")
                        .font(Theme.Typeface.heading(22))
                        .foregroundStyle(Theme.Palette.green)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            IconTile(systemName: "pills.fill", color: Theme.Palette.purple)
            Text("No pills saved yet")
                .font(Theme.Typeface.heading(26))
                .foregroundStyle(Theme.Palette.ink)
            Text("Show Agatha your medication plan and she will put your pills here for you.")
                .font(Theme.Typeface.body(19))
                .foregroundStyle(Theme.Palette.inkSoft)
                .multilineTextAlignment(.center)
            Button { navigator.tab = .scan } label: {
                Label("Scan my medication plan", systemImage: "camera.fill")
            }
            .buttonStyle(PurpleButtonStyle())
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Theme.Palette.lavender, in: RoundedRectangle(cornerRadius: 24))
        .padding(.top, 8)
    }

    /// The user's own meal and bed times from the profile, or sensible defaults.
    private func time(for slot: Slot) -> String {
        let p = model.profile
        let (saved, fallback): (String, String) = switch slot {
        case .morning: (p.breakfast_time, "8:00 AM")
        case .midday: (p.lunch_time, "1:00 PM")
        case .evening: (p.dinner_time, "6:00 PM")
        case .night: (p.bed_time, "9:00 PM")
        }
        let trimmed = saved.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? fallback : trimmed
    }

    private static var todayText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "EEEE, d MMMM"
        return f.string(from: Date())
    }
}

// MARK: - Progress ring

private struct ProgressRing: View {
    let taken: Int
    let total: Int

    var body: some View {
        ZStack {
            Circle().stroke(Theme.Palette.lavender, lineWidth: 10)
            Circle()
                .trim(from: 0, to: total == 0 ? 0 : CGFloat(taken) / CGFloat(total))
                .stroke(Theme.Palette.purple, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.snappy, value: taken)
            VStack(spacing: 0) {
                Text("\(taken)/\(total)")
                    .font(Theme.Typeface.heading(24))
                    .foregroundStyle(Theme.Palette.ink)
                Text("taken")
                    .font(Theme.Typeface.body(14))
                    .foregroundStyle(Theme.Palette.inkSoft)
            }
        }
        .frame(width: 88, height: 88)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(taken) of \(total) pills taken today")
    }
}

// MARK: - One dose card

private struct DoseCard: View {
    enum State { case taken, due, later }

    let med: Medication
    let slot: Slot
    let time: String
    let state: State
    let toggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 16) {
                IconTile(systemName: icon, color: iconColor)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(slotLabel) · \(time)")
                        .font(Theme.Typeface.body(18))
                        .foregroundStyle(state == .due ? Theme.Palette.orangeText : Theme.Palette.inkMuted)
                    Text(title)
                        .font(Theme.Typeface.body(22, weight: .bold))
                        .foregroundStyle(Theme.Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if !med.instructions.isEmpty {
                        Text(med.instructions)
                            .font(Theme.Typeface.body(18))
                            .foregroundStyle(Theme.Palette.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    statusLine
                }
                Spacer(minLength: 0)
            }
            if state == .due {
                Button(action: toggle) { Text("Yes, I took it") }
                    .buttonStyle(PurpleButtonStyle())
                    .accessibilityLabel("Yes, I took \(med.name)")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background, in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            if state == .due {
                RoundedRectangle(cornerRadius: 24).stroke(Theme.Palette.orange, lineWidth: 2.5)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .onTapGesture { if state == .taken { toggle() } }
        .accessibilityElement(children: .combine)
        .accessibilityHint(state == .taken ? "Double tap to mark as not taken" : "")
    }

    @ViewBuilder private var statusLine: some View {
        switch state {
        case .taken:
            Label("Taken", systemImage: "checkmark.circle")
                .font(Theme.Typeface.body(19, weight: .bold))
                .foregroundStyle(Theme.Palette.green)
        case .due:
            Label("Not taken yet", systemImage: "clock")
                .font(Theme.Typeface.body(19, weight: .bold))
                .foregroundStyle(Theme.Palette.orangeText)
        case .later:
            Label("Later today", systemImage: "moon")
                .font(Theme.Typeface.body(19))
                .foregroundStyle(Theme.Palette.inkMuted)
        }
    }

    private var title: String {
        let name = [med.name, med.strength].filter { !$0.isEmpty }.joined(separator: " ")
        return "\(name) · \(Self.doseText(med.times.dose(for: slot)))"
    }

    /// "1" -> "1 tablet", "2" -> "2 tablets", anything else as written ("1/2 tablet", "5 ml").
    static func doseText(_ raw: String) -> String {
        let dose = raw.trimmingCharacters(in: .whitespaces)
        guard let n = Double(dose.replacingOccurrences(of: ",", with: ".")) else { return dose }
        return n == 1 ? "1 tablet" : "\(dose) tablets"
    }

    private var slotLabel: String {
        switch slot {
        case .morning: "Morning"
        case .midday: "Midday"
        case .evening: "Evening"
        case .night: "Night"
        }
    }

    private var icon: String {
        switch state {
        case .taken: "checkmark"
        case .due: "pills.fill"
        case .later: "capsule.fill"
        }
    }

    private var iconColor: Color {
        switch state {
        case .taken: Theme.Palette.green
        case .due: Theme.Palette.orange
        case .later: Theme.Palette.pink
        }
    }

    private var background: Color {
        switch state {
        case .taken: Theme.Palette.mint
        case .due: Theme.Palette.peach
        case .later: Theme.Palette.lavenderLight
        }
    }
}

#Preview {
    PillsView()
        .environmentObject(ChatModel())
        .environmentObject(Navigator())
}
