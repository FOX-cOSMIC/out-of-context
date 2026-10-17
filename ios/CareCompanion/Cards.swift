import SwiftUI

/// Cards Claude puts into the conversation.
struct CardView: View {
    @EnvironmentObject private var model: ChatModel
    let card: Card
    let messageID: UUID
    let cardIndex: Int
    let answer: Bool?

    var body: some View {
        switch card.type {
        case "schedule":
            // Each time of day is its own coloured card (mint morning, peach midday, lavender evening).
            VStack(alignment: .leading, spacing: Theme.Metrics.spacingLarge) { schedule }
        case "appointments":
            chrome { AppointmentList(appointments: model.plan.appointments) }
        case "confirm_medications", "confirm_appointments":
            chrome { confirm }
        default:
            EmptyView()
        }
    }

    /// White rounded card with a soft lavender outline and shadow.
    private func chrome<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.spacingLarge) { content() }
            .foregroundStyle(Theme.Colors.textPrimary)
            .padding(Theme.Metrics.welcomePadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Metrics.cornerLarge, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.Metrics.cornerLarge, style: .continuous).stroke(Theme.Colors.cardBorder, lineWidth: Theme.Metrics.cardBorderWidth))
            .shadow(color: Theme.Colors.shadow, radius: 10, y: 4)
    }

    // MARK: Schedule with "taken" buttons

    @ViewBuilder private var schedule: some View {
        let slots = card.slot.flatMap(Slot.init(rawValue:)).map { [$0] } ?? Slot.allCases
        let rows = slots.flatMap { slot in
            model.plan.medications
                .filter { !$0.times.dose(for: slot).isEmpty }
                .map { (slot, $0) }
        }
        if rows.isEmpty {
            chrome { Text("Nothing on your plan for this time.").font(Theme.Fonts.message) }
        }
        ForEach(slots, id: \.self) { slot in
            let meds = rows.filter { $0.0 == slot }.map(\.1)
            if !meds.isEmpty {
              VStack(alignment: .leading, spacing: Theme.Metrics.spacingMedium) {
                HStack {
                    Image(systemName: slot.icon).font(Theme.Fonts.skillIcon).foregroundStyle(Theme.Palette.orangeDark)
                    Text(slot.label).font(Theme.Fonts.cardTitle).foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    let done = meds.filter { model.isTaken($0, slot: slot) }.count
                    Text("\(done) of \(meds.count)").font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textSecondary)
                }
                ForEach(meds) { med in
                    let taken = model.isTaken(med, slot: slot)
                    HStack(alignment: .center, spacing: Theme.Metrics.spacingLarge) {
                        VStack(alignment: .leading, spacing: Theme.Metrics.spacingTiny) {
                            Text("\(med.name)  \(med.times.dose(for: slot))").font(Theme.Fonts.itemTitle)
                                .foregroundStyle(Theme.Colors.textPrimary)
                                .strikethrough(taken, color: Theme.Colors.textSecondaryColor)
                            Text([med.purpose, med.instructions].filter { !$0.isEmpty }.joined(separator: ". "))
                                .font(Theme.Fonts.cardBody).foregroundStyle(Theme.Colors.textSecondary)
                        }
                        Spacer()
                        Button { model.toggleTaken(med, slot: slot) } label: {
                            Label(taken ? "Taken" : "Take", systemImage: taken ? "checkmark.circle.fill" : "circle")
                                .font(Theme.Fonts.headline)
                                .padding(.horizontal, Theme.Metrics.takeButtonHorizontalPadding).padding(.vertical, Theme.Metrics.takeButtonVerticalPadding)
                                .frame(minHeight: Theme.Metrics.minTouch)
                                .background(taken ? Theme.Colors.takeButtonBackground : Theme.Colors.accent, in: Capsule())
                                .foregroundStyle(taken ? Theme.Colors.success : Theme.Colors.onColor)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(taken ? "\(med.name) taken" : "Mark \(med.name) as taken")
                    }
                    .padding(Theme.Metrics.fieldPadding)
                    .background(Theme.Palette.white.opacity(0.7), in: RoundedRectangle(cornerRadius: Theme.Metrics.cornerMedium, style: .continuous))
                }
              }
              .padding(Theme.Metrics.screenPadding)
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(Theme.Colors.slotBackground(slot), in: RoundedRectangle(cornerRadius: Theme.Metrics.cornerLarge, style: .continuous))
            }
        }
    }

    // MARK: "Here is what I read, is this right?"

    @ViewBuilder private var confirm: some View {
        Text("Here is what I read").font(Theme.Fonts.cardTitle)
        if let unclear = card.unclear, !unclear.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Metrics.spacingXSmall) {
                Label("I could not read everything", systemImage: "exclamationmark.triangle.fill").font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.Palette.orangeText)
                ForEach(unclear, id: \.self) { Text($0) }
            }
            .padding(Theme.Metrics.fieldPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.warningBackground, in: RoundedRectangle(cornerRadius: Theme.Metrics.cornerSmall))
        }
        ForEach(card.medications ?? []) { med in
            VStack(alignment: .leading, spacing: Theme.Metrics.spacingTiny) {
                Text("\(med.name) \(med.strength)").font(Theme.Fonts.itemTitle)
                if !med.purpose.isEmpty { Text(med.purpose).font(Theme.Fonts.cardBody) }
                Text(Slot.allCases
                    .compactMap { slot in med.times.dose(for: slot).isEmpty ? nil : "\(slot.label): \(med.times.dose(for: slot))" }
                    .joined(separator: " · "))
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.Palette.purpleDeep)
                if !med.instructions.isEmpty { Text(med.instructions).font(Theme.Fonts.cardBody).foregroundStyle(Theme.Colors.textSecondary) }
            }
            Divider().overlay(Theme.Colors.cardBorder)
        }
        if let appts = card.appointments { AppointmentList(appointments: appts) }
        Text("Please check every line against your paper. AI can make mistakes.")
            .font(Theme.Fonts.hint).foregroundStyle(Theme.Colors.textSecondary)
        if let answer {
            Label(answer ? "Saved" : "Not saved", systemImage: answer ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(Theme.Fonts.itemTitle)
                .foregroundStyle(answer ? Theme.Colors.success : Theme.Colors.textSecondaryColor)
        } else {
            HStack(spacing: Theme.Metrics.spacingLarge) {
                Button { Task { await model.answer(messageID: messageID, cardIndex: cardIndex, yes: true) } } label: {
                    Label("Yes, right", systemImage: "checkmark").frame(maxWidth: .infinity, minHeight: Theme.Metrics.confirmButtonHeight)
                }
                .buttonStyle(BigButtonStyle(color: Theme.Colors.accent))
                Button { Task { await model.answer(messageID: messageID, cardIndex: cardIndex, yes: false) } } label: {
                    Label("No", systemImage: "xmark").frame(maxWidth: .infinity, minHeight: Theme.Metrics.confirmButtonHeight)
                }
                .buttonStyle(SoftButtonStyle())
            }
            .disabled(!model.canSend)
        }
    }
}

struct AppointmentList: View {
    let appointments: [Appointment]

    var body: some View {
        if appointments.isEmpty {
            Text("No appointments saved yet.").font(Theme.Fonts.message).foregroundStyle(Theme.Colors.textPrimary)
        }
        ForEach(appointments) { appt in
            VStack(alignment: .leading, spacing: Theme.Metrics.spacingXSmall) {
                Label(appt.title, systemImage: "calendar").font(Theme.Fonts.itemTitle).foregroundStyle(Theme.Colors.textPrimary)
                Text("\(appt.date) \(appt.time)").font(Theme.Fonts.headline).foregroundStyle(Theme.Palette.purpleDeep)
                if !appt.place.isEmpty { Text(appt.place).font(Theme.Fonts.cardBody) }
                if !appt.bring.isEmpty { Text("Bring: \(appt.bring)").font(Theme.Fonts.cardBody) }
                if !appt.preparation.isEmpty { Text(appt.preparation).font(Theme.Fonts.cardBody).foregroundStyle(Theme.Colors.textSecondary) }
            }
            .padding(Theme.Metrics.fieldPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Palette.mint, in: RoundedRectangle(cornerRadius: Theme.Metrics.cornerMedium, style: .continuous))
        }
    }
}

extension Slot {
    /// Little picture next to the time of day on a schedule card.
    var icon: String {
        switch self {
        case .morning: "sunrise.fill"
        case .midday: "sun.max.fill"
        case .evening: "sunset.fill"
        case .night: "moon.stars.fill"
        }
    }
}
