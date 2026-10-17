import SwiftUI

/// Cards Claude puts into the conversation.
struct CardView: View {
    @EnvironmentObject private var model: ChatModel
    let card: Card
    let messageID: UUID
    let cardIndex: Int
    let answer: Bool?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.spacingLarge) {
            switch card.type {
            case "schedule": schedule
            case "appointments": AppointmentList(appointments: model.plan.appointments)
            case "confirm_medications", "confirm_appointments": confirm
            default: EmptyView()
            }
        }
        .padding(Theme.Metrics.screenPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Metrics.cornerLarge))
        .overlay(RoundedRectangle(cornerRadius: Theme.Metrics.cornerLarge).stroke(Theme.Colors.cardBorder, lineWidth: Theme.Metrics.cardBorderWidth))
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
            Text("Nothing on your plan for this time.").font(Theme.Fonts.message)
        }
        ForEach(slots, id: \.self) { slot in
            let meds = rows.filter { $0.0 == slot }.map(\.1)
            if !meds.isEmpty {
                Text(slot.label).font(Theme.Fonts.cardTitle)
                ForEach(meds) { med in
                    let taken = model.isTaken(med, slot: slot)
                    HStack(alignment: .center, spacing: Theme.Metrics.spacingLarge) {
                        VStack(alignment: .leading, spacing: Theme.Metrics.spacingTiny) {
                            Text("\(med.name)  \(med.times.dose(for: slot))").font(Theme.Fonts.itemTitle)
                            Text([med.purpose, med.instructions].filter { !$0.isEmpty }.joined(separator: ". "))
                                .font(Theme.Fonts.cardBody).foregroundStyle(Theme.Colors.textSecondary)
                        }
                        Spacer()
                        Button { model.toggleTaken(med, slot: slot) } label: {
                            Label(taken ? "Taken" : "Take", systemImage: taken ? "checkmark.circle.fill" : "circle")
                                .font(Theme.Fonts.headline)
                                .padding(.horizontal, Theme.Metrics.takeButtonHorizontalPadding).padding(.vertical, Theme.Metrics.takeButtonVerticalPadding)
                                .background(taken ? Theme.Colors.success : Theme.Colors.takeButtonBackground, in: Capsule())
                                .foregroundStyle(taken ? Theme.Colors.onColor : Theme.Colors.accent)
                        }
                        .accessibilityLabel(taken ? "\(med.name) taken" : "Mark \(med.name) as taken")
                    }
                    .padding(.vertical, Theme.Metrics.scheduleRowPadding)
                }
            }
        }
    }

    // MARK: "Here is what I read, is this right?"

    @ViewBuilder private var confirm: some View {
        Text("Here is what I read").font(Theme.Fonts.cardTitle)
        if let unclear = card.unclear, !unclear.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Metrics.spacingXSmall) {
                Label("I could not read everything", systemImage: "exclamationmark.triangle.fill").font(Theme.Fonts.headline)
                ForEach(unclear, id: \.self) { Text($0) }
            }
            .padding(Theme.Metrics.fieldPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.warningBackground, in: RoundedRectangle(cornerRadius: Theme.Metrics.cornerSmall))
        }
        ForEach(card.medications ?? []) { med in
            VStack(alignment: .leading, spacing: Theme.Metrics.spacingTiny) {
                Text("\(med.name) \(med.strength)").font(Theme.Fonts.itemTitle)
                if !med.purpose.isEmpty { Text(med.purpose) }
                Text(Slot.allCases
                    .compactMap { slot in med.times.dose(for: slot).isEmpty ? nil : "\(slot.label): \(med.times.dose(for: slot))" }
                    .joined(separator: " · "))
                    .font(Theme.Fonts.headline)
                if !med.instructions.isEmpty { Text(med.instructions).foregroundStyle(Theme.Colors.textSecondary) }
            }
            Divider()
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
                .buttonStyle(BigButtonStyle(color: Theme.Colors.success))
                Button { Task { await model.answer(messageID: messageID, cardIndex: cardIndex, yes: false) } } label: {
                    Label("No", systemImage: "xmark").frame(maxWidth: .infinity, minHeight: Theme.Metrics.confirmButtonHeight)
                }
                .buttonStyle(BigButtonStyle(color: Theme.Colors.neutralButton))
            }
            .disabled(!model.canSend)
        }
    }
}

struct AppointmentList: View {
    let appointments: [Appointment]

    var body: some View {
        if appointments.isEmpty {
            Text("No appointments saved yet.").font(Theme.Fonts.message)
        }
        ForEach(appointments) { appt in
            VStack(alignment: .leading, spacing: Theme.Metrics.spacingXSmall) {
                Label(appt.title, systemImage: "calendar").font(Theme.Fonts.itemTitle)
                Text("\(appt.date) \(appt.time)").font(Theme.Fonts.headline)
                if !appt.place.isEmpty { Text(appt.place) }
                if !appt.bring.isEmpty { Text("Bring: \(appt.bring)") }
                if !appt.preparation.isEmpty { Text(appt.preparation).foregroundStyle(Theme.Colors.textSecondary) }
            }
        }
    }
}
