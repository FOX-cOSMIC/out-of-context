import SwiftUI

/// "My calendar": a month grid with a dot on days that have something on, the chosen day's events,
/// and the next five things coming up as big cards.
struct CalendarView: View {
    var history: DemoHistory = .shared
    /// The appointments saved in the app now (e.g. added by voice); the demo ones are in `history` already.
    var appointments: [Appointment] = []
    @Environment(\.dismiss) private var dismiss
    @AppStorage("calendarGoogle") private var googleConnected = false
    @AppStorage("calendarApple") private var appleConnected = false

    @State private var month: Date = DemoHistory.calendar.dateInterval(of: .month, for: Date())!.start
    @State private var selected: Date = DemoHistory.calendar.startOfDay(for: Date())

    private var cal: Calendar { DemoHistory.calendar }

    /// The app's own appointments, plus the events of each connected calendar.
    private var visible: [DemoHistory.CalendarEvent] {
        let base = history.visibleEvents(google: googleConnected, apple: appleConnected)
        let added = appointments.compactMap(DemoHistory.event(for:)).filter { new in !base.contains { $0.id == new.id } }
        return (base + added).sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SheetHeader(title: "My calendar", close: { dismiss() })

                if !googleConnected && !appleConnected {
                    Label("Connect your calendar in Settings to see all your events here.", systemImage: "calendar.badge.plus")
                        .font(Theme.Typeface.body(19))
                        .foregroundStyle(Theme.Palette.inkSoft)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.Palette.lavenderLight, in: RoundedRectangle(cornerRadius: 18))
                        .fixedSize(horizontal: false, vertical: true)
                }

                monthGrid
                    .padding(16)
                    .background(Theme.Palette.white, in: RoundedRectangle(cornerRadius: 24))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.Palette.lavenderBorder, lineWidth: 2))

                // The chosen day
                VStack(alignment: .leading, spacing: 12) {
                    Text(dayTitle(selected))
                        .font(Theme.Typeface.heading(24))
                        .foregroundStyle(Theme.Palette.ink)
                    let dayEvents = history.events(on: selected, in: visible)
                    if dayEvents.isEmpty {
                        Text("Nothing planned on this day.")
                            .font(Theme.Typeface.body(19))
                            .foregroundStyle(Theme.Palette.inkSoft)
                    } else {
                        ForEach(dayEvents) { EventCard(event: $0, showDate: false) }
                    }
                }

                // Coming up
                Text("Coming up")
                    .font(Theme.Typeface.heading(26))
                    .foregroundStyle(Theme.Palette.ink)
                    .padding(.top, 6)
                ForEach(history.upcoming(5, in: visible)) { EventCard(event: $0, showDate: true) }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
        }
        .background(Theme.Palette.page.ignoresSafeArea())
    }

    // MARK: - Month grid

    private var monthGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
        let first = month
        let count = cal.range(of: .day, in: .month, for: first)!.count
        let lead = (cal.component(.weekday, from: first) + 5) % 7 // Monday first
        let days = (0..<count).map { cal.date(byAdding: .day, value: $0, to: first)! }
        let today = cal.startOfDay(for: Date())

        return VStack(spacing: 12) {
            HStack {
                monthButton("chevron.left", label: "Previous month", by: -1)
                Spacer()
                Text(DemoHistoryFormat.month(first))
                    .font(Theme.Typeface.heading(24))
                    .foregroundStyle(Theme.Palette.ink)
                Spacer()
                monthButton("chevron.right", label: "Next month", by: 1)
            }
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"].enumerated()), id: \.offset) { _, name in
                    Text(name)
                        .font(Theme.Typeface.body(16, weight: .bold))
                        .foregroundStyle(Theme.Palette.inkSoft)
                }
                ForEach(0..<lead, id: \.self) { _ in Color.clear.frame(height: 50) }
                ForEach(days, id: \.self) { day in
                    let isToday = day == today
                    let isSelected = day == selected
                    let hasEvents = !history.events(on: day, in: visible).isEmpty
                    Button { withAnimation(.snappy) { selected = day } } label: {
                        VStack(spacing: 3) {
                            Text("\(cal.component(.day, from: day))")
                                .font(Theme.Typeface.body(19, weight: isToday || isSelected ? .bold : .regular))
                                .foregroundStyle(isSelected ? .white : Theme.Palette.ink)
                            Circle()
                                .fill(hasEvents ? (isSelected ? Color.white : Theme.Palette.orange) : .clear)
                                .frame(width: 7, height: 7)
                        }
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background {
                            if isSelected {
                                Circle().fill(Theme.Palette.purple)
                            } else if isToday {
                                Circle().fill(Theme.Palette.lavender)
                                    .overlay(Circle().stroke(Theme.Palette.purple, lineWidth: 2))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(dayTitle(day) + (isToday ? ", today" : "") + (hasEvents ? ", has events" : ""))
                }
            }
        }
    }

    private func monthButton(_ icon: String, label: String, by step: Int) -> some View {
        Button {
            withAnimation(.snappy) { month = cal.date(byAdding: .month, value: step, to: month)! }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.Palette.purple)
                .frame(width: 52, height: 52)
                .background(Theme.Palette.lavender, in: Circle())
        }
        .accessibilityLabel(label)
    }

    private func dayTitle(_ day: Date) -> String {
        let prefix = cal.isDateInToday(day) ? "Today, " : ""
        return prefix + DemoHistoryFormat.day(day)
    }
}

/// Date texts for the calendar ("October 2026", "Saturday 17 October").
enum DemoHistoryFormat {
    private static func string(_ pattern: String, _ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.calendar = DemoHistory.calendar
        f.dateFormat = pattern
        return f.string(from: date)
    }
    static func month(_ date: Date) -> String { string("MMMM yyyy", date) }
    static func day(_ date: Date) -> String { string("EEEE d MMMM", date) }
}

// MARK: - One event card

private struct EventCard: View {
    let event: DemoHistory.CalendarEvent
    let showDate: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            IconTile(systemName: event.kind.icon, color: color)
            VStack(alignment: .leading, spacing: 5) {
                Text(when)
                    .font(Theme.Typeface.body(18, weight: .bold))
                    .foregroundStyle(Theme.Palette.inkMuted)
                Text(event.title)
                    .font(Theme.Typeface.body(22, weight: .bold))
                    .foregroundStyle(Theme.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Label(event.place, systemImage: "mappin.and.ellipse")
                    .font(Theme.Typeface.body(19))
                    .foregroundStyle(Theme.Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                if event.source != .app {
                    // Only shown when that calendar is connected (otherwise the event is hidden).
                    Label(event.source.label, systemImage: "calendar")
                        .font(Theme.Typeface.body(15, weight: .bold))
                        .foregroundStyle(Theme.Palette.inkMuted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Theme.Palette.white.opacity(0.8), in: Capsule())
                }
                if let note = event.note {
                    Text(note)
                        .font(Theme.Typeface.body(19))
                        .foregroundStyle(Theme.Palette.ink)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.Palette.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 14))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background, in: RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }

    private var when: String {
        let time = DemoHistory.timeText(event.date)
        guard showDate else { return time }
        let cal = DemoHistory.calendar
        let day = cal.isDateInToday(event.date) ? "Today"
            : cal.isDateInTomorrow(event.date) ? "Tomorrow"
            : DemoHistoryFormat.day(event.date)
        return "\(day) · \(time)"
    }

    private var color: Color {
        switch event.kind {
        case .doctor: Theme.Palette.green
        case .pharmacy: Theme.Palette.orangeDark
        case .social: Theme.Palette.pink
        case .other: Theme.Palette.purple
        }
    }

    private var background: Color {
        switch event.kind {
        case .doctor: Theme.Palette.mint
        case .pharmacy: Theme.Palette.peach
        case .social: Theme.Palette.lavender
        case .other: Theme.Palette.lavenderLight
        }
    }
}

#Preview {
    CalendarView()
}
