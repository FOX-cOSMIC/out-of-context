import SwiftUI

/// Cards Claude puts into the conversation.
struct CardView: View {
    @EnvironmentObject private var model: ChatModel
    let card: Card
    let messageID: UUID
    let cardIndex: Int
    let answer: Bool?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch card.type {
            case "schedule": schedule
            case "appointments": AppointmentList(appointments: model.plan.appointments)
            case "confirm_medications", "confirm_appointments": confirm
            default: EmptyView()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.accentColor.opacity(0.3), lineWidth: 2))
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
            Text("Nothing on your plan for this time.").font(.title3)
        }
        ForEach(slots, id: \.self) { slot in
            let meds = rows.filter { $0.0 == slot }.map(\.1)
            if !meds.isEmpty {
                Text(slot.label).font(.title2.bold())
                ForEach(meds) { med in
                    let taken = model.isTaken(med, slot: slot)
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(med.name)  \(med.times.dose(for: slot))").font(.title3.bold())
                            Text([med.purpose, med.instructions].filter { !$0.isEmpty }.joined(separator: ". "))
                                .font(.body).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { model.toggleTaken(med, slot: slot) } label: {
                            Label(taken ? "Taken" : "Take", systemImage: taken ? "checkmark.circle.fill" : "circle")
                                .font(.headline)
                                .padding(.horizontal, 12).padding(.vertical, 10)
                                .background(taken ? Color.green : Color.accentColor.opacity(0.12), in: Capsule())
                                .foregroundStyle(taken ? .white : .accentColor)
                        }
                        .accessibilityLabel(taken ? "\(med.name) taken" : "Mark \(med.name) as taken")
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: "Here is what I read, is this right?"

    @ViewBuilder private var confirm: some View {
        Text("Here is what I read").font(.title2.bold())
        if let unclear = card.unclear, !unclear.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Label("I could not read everything", systemImage: "exclamationmark.triangle.fill").font(.headline)
                ForEach(unclear, id: \.self) { Text($0) }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
        }
        ForEach(card.medications ?? []) { med in
            VStack(alignment: .leading, spacing: 2) {
                Text("\(med.name) \(med.strength)").font(.title3.bold())
                if !med.purpose.isEmpty { Text(med.purpose) }
                Text(Slot.allCases
                    .compactMap { slot in med.times.dose(for: slot).isEmpty ? nil : "\(slot.label): \(med.times.dose(for: slot))" }
                    .joined(separator: " · "))
                    .font(.headline)
                if !med.instructions.isEmpty { Text(med.instructions).foregroundStyle(.secondary) }
            }
            Divider()
        }
        if let appts = card.appointments { AppointmentList(appointments: appts) }
        Text("Please check every line against your paper. AI can make mistakes.")
            .font(.callout).foregroundStyle(.secondary)
        if let answer {
            Label(answer ? "Saved" : "Not saved", systemImage: answer ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title3.bold())
                .foregroundStyle(answer ? .green : .secondary)
        } else {
            HStack(spacing: 12) {
                Button { Task { await model.answer(messageID: messageID, cardIndex: cardIndex, yes: true) } } label: {
                    Label("Yes, right", systemImage: "checkmark").frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(BigButtonStyle(color: .green))
                Button { Task { await model.answer(messageID: messageID, cardIndex: cardIndex, yes: false) } } label: {
                    Label("No", systemImage: "xmark").frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(BigButtonStyle(color: .gray))
            }
            .disabled(!model.canSend)
        }
    }
}

struct AppointmentList: View {
    let appointments: [Appointment]

    var body: some View {
        if appointments.isEmpty {
            Text("No appointments saved yet.").font(.title3)
        }
        ForEach(appointments) { appt in
            VStack(alignment: .leading, spacing: 4) {
                Label(appt.title, systemImage: "calendar").font(.title3.bold())
                Text("\(appt.date) \(appt.time)").font(.headline)
                if !appt.place.isEmpty { Text(appt.place) }
                if !appt.bring.isEmpty { Text("Bring: \(appt.bring)") }
                if !appt.preparation.isEmpty { Text(appt.preparation).foregroundStyle(.secondary) }
            }
        }
    }
}
