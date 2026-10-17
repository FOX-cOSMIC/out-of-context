import Foundation

/// Mock history for the demo person Margaret Weber: a month of doses, how she felt, and her calendar.
/// Everything is computed relative to today with a fixed pattern (no randomness), so the demo
/// always looks current and shows the same story every time.
struct DemoHistory {

    // MARK: - Types

    enum DoseStatus { case taken, missed }

    /// One scheduled dose on one day.
    struct DoseEntry: Identifiable {
        let day: Date          // start of that day
        let slot: Slot         // .morning or .evening
        let medName: String    // short name, e.g. "Metformin"
        let status: DoseStatus
        let time: Date?        // when it was taken (nil when missed)
        var id: String { "\(day.timeIntervalSince1970)|\(slot.rawValue)|\(medName)" }
    }

    enum Mood: String {
        case good, okay, notWell

        var label: String {
            switch self {
            case .good: "Good"
            case .okay: "Okay"
            case .notWell: "Not well"
            }
        }
        var icon: String {
            switch self {
            case .good: "sun.max.fill"
            case .okay: "cloud.sun.fill"
            case .notWell: "cloud.rain.fill"
            }
        }
    }

    /// Something Margaret told Agatha about her day.
    struct MoodEntry: Identifiable {
        let date: Date
        let mood: Mood
        let text: String
        var id: String { "\(date.timeIntervalSince1970)|\(text)" }
    }

    enum EventKind { case doctor, pharmacy, social, other

        var icon: String {
            switch self {
            case .doctor: "stethoscope"
            case .pharmacy: "cross.case.fill"
            case .social: "heart.fill"
            case .other: "star.fill"
            }
        }
    }

    struct CalendarEvent: Identifiable {
        let date: Date
        let title: String
        let place: String
        let kind: EventKind
        var note: String? = nil
        /// True for the appointments saved in the app's own plan (always shown).
        var fromPlan: Bool = false
        var id: String { "\(date.timeIntervalSince1970)|\(title)" }

        /// Where the event comes from (demo: a fixed rule, no real calendar is read).
        var source: CalendarSource {
            if fromPlan { return .app }
            return kind == .doctor || kind == .pharmacy ? .apple : .google
        }
    }

    /// The app's own plan, or one of the two (simulated) connected calendars.
    enum CalendarSource: String, CaseIterable {
        case app, google, apple

        var label: String {
            switch self {
            case .app: "Agatha"
            case .google: "Google Calendar"
            case .apple: "Apple Calendar"
            }
        }
        /// The @AppStorage key that says whether this calendar is "connected" (nil for the app's own).
        var storageKey: String? {
            switch self {
            case .app: nil
            case .google: "calendarGoogle"
            case .apple: "calendarApple"
            }
        }
        var isConnected: Bool {
            guard let key = storageKey else { return true }
            return UserDefaults.standard.bool(forKey: key)
        }
    }

    /// How one day of doses went, for the coloured dots.
    struct DaySummary: Identifiable {
        let day: Date
        let taken: Int
        let total: Int
        var allTaken: Bool { taken == total }
        var id: Date { day }
    }

    // MARK: - Shared instance

    /// Built once per app launch from today's date.
    static let shared = DemoHistory(today: Date())

    // MARK: - Data

    let today: Date                 // start of today
    let doses: [DoseEntry]          // the last 30 full days (yesterday back to 30 days ago)
    let moods: [MoodEntry]          // newest first
    let events: [CalendarEvent]     // sorted by date, 30 days back to 30 days ahead
    let annaWeekend: Date           // Saturday of the weekend at Anna's (many missed doses)

    static var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "en_GB")
        c.firstWeekday = 2 // Monday
        return c
    }()

    /// Morning: Ramipril, Metformin, ASS 100, Pantoprazole. Evening: Metformin, Simvastatin.
    static let schedule: [(Slot, String)] = [
        (.morning, "Pantoprazole"), (.morning, "Ramipril"), (.morning, "Metformin"), (.morning, "ASS 100"),
        (.evening, "Metformin"), (.evening, "Simvastatin"),
    ]

    init(today now: Date) {
        let cal = Self.calendar
        let today = cal.startOfDay(for: now)
        self.today = today

        func day(_ offset: Int) -> Date { cal.date(byAdding: .day, value: offset, to: today)! }
        func weekday(_ offset: Int) -> Int { cal.component(.weekday, from: day(offset)) } // 1 = Sunday
        /// Days-ago offset of the first given weekday found in the range (1 = Sun, 4 = Wed, 7 = Sat).
        func daysAgo(_ wd: Int, in range: ClosedRange<Int>) -> Int {
            range.first { weekday(-$0) == wd } ?? range.lowerBound
        }

        // The story behind the missed doses (offsets are "days ago").
        let annaSaturday = daysAgo(7, in: 15...21)       // the weekend at Anna's, 2-3 weeks ago
        let annaSunday = annaSaturday - 1
        let choirWednesday = daysAgo(4, in: 8...14)      // forgot evening tablets after choir
        let lastSunday = daysAgo(1, in: 1...7)

        var missed = Set<String>()
        func miss(_ offset: Int, _ slot: Slot, _ name: String) { missed.insert("\(offset)|\(slot.rawValue)|\(name)") }
        // Evening Metformin is the weak spot: twice this week, a few times before.
        miss(2, .evening, "Metformin")
        miss(5, .evening, "Metformin")
        miss(choirWednesday, .evening, "Metformin")
        miss(choirWednesday, .evening, "Simvastatin")
        miss(23, .evening, "Metformin")
        miss(27, .evening, "Metformin")
        miss(10, .evening, "Simvastatin")
        // The weekend at Anna's: the tablet box stayed at home.
        miss(annaSaturday, .evening, "Metformin")
        miss(annaSaturday, .evening, "Simvastatin")
        miss(annaSunday, .morning, "Pantoprazole")
        miss(annaSunday, .morning, "ASS 100")
        miss(annaSunday, .evening, "Simvastatin")
        // One sleepy morning.
        miss(25, .morning, "Ramipril")

        var doses: [DoseEntry] = []
        for offset in stride(from: 30, through: 1, by: -1) {
            let d = day(-offset)
            // Plausible times: breakfast 08:05-08:40, dinner 18:10-19:30, Pantoprazole 30 min before breakfast.
            let morningMinute = 5 + (offset * 7 + 3) % 36
            let eveningMinute = 10 + (offset * 13 + 5) % 81
            for (i, (slot, name)) in Self.schedule.enumerated() {
                let isMissed = missed.contains("\(offset)|\(slot.rawValue)|\(name)")
                var time: Date? = nil
                if !isMissed {
                    let minutes: Int
                    if slot == .morning {
                        minutes = 8 * 60 + morningMinute + (name == "Pantoprazole" ? -30 : i)
                    } else {
                        minutes = 18 * 60 + eveningMinute + (i - 4)
                    }
                    time = cal.date(byAdding: .minute, value: minutes, to: d)
                }
                doses.append(DoseEntry(day: d, slot: slot, medName: name,
                                       status: isMissed ? .missed : .taken, time: time))
            }
        }
        self.doses = doses
        self.annaWeekend = day(-annaSaturday)

        // How she felt, in her own words.
        func at(_ offset: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            cal.date(bySettingHour: hour, minute: minute, second: 0, of: day(offset))!
        }
        let moods: [MoodEntry] = [
            MoodEntry(date: at(-lastSunday, 17, 30), mood: .good, text: "Lovely walk with Anna by the river."),
            MoodEntry(date: at(-2, 21, 40), mood: .okay, text: "Fell asleep in front of the TV and forgot my evening Metformin."),
            MoodEntry(date: at(-4, 9, 15), mood: .notWell, text: "Felt a bit dizzy after standing up."),
            MoodEntry(date: at(-9, 8, 30), mood: .okay, text: "Slept badly, the neighbours were loud."),
            MoodEntry(date: at(-choirWednesday, 20, 45), mood: .okay, text: "Forgot my evening tablets, was at choir."),
            MoodEntry(date: at(-11, 16, 0), mood: .notWell, text: "Knee hurting on the stairs."),
            MoodEntry(date: at(-12, 12, 15), mood: .okay, text: "Saw Dr Hoffmann. Blood pressure a bit high, I should keep a diary."),
            MoodEntry(date: at(-annaSunday, 19, 0), mood: .okay, text: "Lovely weekend at Anna's, but I left my tablet box at home."),
            MoodEntry(date: at(-22, 15, 30), mood: .good, text: "Did the whole crossword. Feeling sharp!"),
            MoodEntry(date: at(-26, 18, 0), mood: .good, text: "New haircut, feel like a new woman."),
        ]
        self.moods = moods.sorted { $0.date > $1.date }

        // Her calendar, 30 days back and 30 days ahead.
        var events: [CalendarEvent] = []
        for offset in -30...30 {
            switch weekday(offset) {
            case 4:
                events.append(CalendarEvent(date: at(offset, 17), title: "Choir practice",
                                            place: "St. Mary's parish hall", kind: .social,
                                            note: "Take your evening tablets before you leave."))
            case 1:
                events.append(CalendarEvent(date: at(offset, 15), title: "Anna visits",
                                            place: "At home", kind: .social))
            default: break
            }
        }
        events += [
            CalendarEvent(date: at(-12, 10, 0), title: "Check-up with Dr Hoffmann",
                          place: "Example GP Practice, Lindenstraße 5", kind: .doctor,
                          note: "Blood pressure 145/85. Keep a blood pressure diary for 2 weeks."),
            CalendarEvent(date: at(-12, 11, 30), title: "Pick up medicines",
                          place: "Example Pharmacy", kind: .pharmacy,
                          note: "Picked up Ramipril and Metformin."),
            CalendarEvent(date: at(-26, 14, 0), title: "Hairdresser",
                          place: "Example Hair Salon", kind: .other),
            CalendarEvent(date: at(5, 10, 0), title: "Pick up medicines",
                          place: "Example Pharmacy", kind: .pharmacy,
                          note: "Bring the new prescription for Simvastatin."),
            CalendarEvent(date: at(10, 8, 0), title: "Blood test",
                          place: "Example GP Practice, Lindenstraße 5", kind: .doctor,
                          note: "Fasting: no breakfast, water is fine. Bring your blood pressure diary and insurance card."),
            CalendarEvent(date: at(20, 14, 0), title: "Hairdresser",
                          place: "Example Hair Salon", kind: .other),
        ]
        // The two appointments from her plan (same dates as DemoPerson).
        let parse = DateFormatter()
        parse.locale = Locale(identifier: "en_GB")
        parse.calendar = cal
        parse.dateFormat = "EEEE, d MMMM yyyy HH:mm"
        for appt in DemoPerson.plan.appointments {
            guard let date = parse.date(from: "\(appt.date) \(appt.time)") else { continue }
            events.append(CalendarEvent(date: date, title: appt.title, place: appt.place, kind: .doctor,
                                        note: "Bring: \(appt.bring). \(appt.preparation)", fromPlan: true))
        }
        self.events = events.sorted { $0.date < $1.date }
    }

    // MARK: - Doses

    /// Doses of the last `days` full days (yesterday counts as day 1).
    func doses(lastDays days: Int) -> [DoseEntry] {
        let start = Self.calendar.date(byAdding: .day, value: -days, to: today)!
        return doses.filter { $0.day >= start && $0.day < today }
    }

    /// Adherence in percent (0-100) over the last `days` days.
    func adherence(lastDays days: Int) -> Int {
        let list = doses(lastDays: days)
        guard !list.isEmpty else { return 0 }
        let taken = list.filter { $0.status == .taken }.count
        return Int((Double(taken) / Double(list.count) * 100).rounded())
    }

    var adherence7: Int { adherence(lastDays: 7) }
    var adherence30: Int { adherence(lastDays: 30) }

    /// Missed doses in the last 7 days, oldest first.
    var missedThisWeek: [DoseEntry] { doses(lastDays: 7).filter { $0.status == .missed } }

    /// One dot per day, oldest first.
    func days(lastDays days: Int) -> [DaySummary] {
        let grouped = Dictionary(grouping: doses(lastDays: days), by: \.day)
        return grouped.keys.sorted().map { day in
            let list = grouped[day]!
            return DaySummary(day: day, taken: list.filter { $0.status == .taken }.count, total: list.count)
        }
    }

    // MARK: - Plain-English summaries

    private static func format(_ pattern: String, _ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.calendar = calendar
        f.dateFormat = pattern
        return f.string(from: date)
    }

    static func weekdayName(_ date: Date) -> String { format("EEEE", date) }
    static func shortDate(_ date: Date) -> String { format("EEE d MMM", date) }
    static func timeText(_ date: Date) -> String { format("HH:mm", date) }

    /// "evening Metformin on Monday" style lines, grouped by medicine and time of day.
    private func missedPhrases(_ list: [DoseEntry]) -> [String] {
        var order: [String] = []
        var daysByKey: [String: [String]] = [:]
        for d in list {
            let key = "\(d.slot.rawValue) \(d.medName)"
            if daysByKey[key] == nil { order.append(key) }
            daysByKey[key, default: []].append(Self.weekdayName(d.day))
        }
        return order.map { "your \($0) on \(Self.joined(daysByKey[$0]!))" }
    }

    private static func joined(_ items: [String]) -> String {
        switch items.count {
        case 0: ""
        case 1: items[0]
        default: items.dropLast().joined(separator: ", ") + " and " + items.last!
        }
    }

    var weeklySummary: String {
        let week = doses(lastDays: 7)
        let taken = week.filter { $0.status == .taken }.count
        let missed = week.filter { $0.status == .missed }
        var s = "This week you took \(taken) of \(week.count) doses."
        if missed.isEmpty {
            s += " You did not miss a single one. Wonderful!"
        } else {
            s += " You missed \(Self.joined(missedPhrases(missed)))."
        }
        if !missed.contains(where: { $0.slot == .morning }) { s += " Mornings were perfect." }
        return s
    }

    var monthlySummary: String {
        let month = doses(lastDays: 30)
        let taken = month.filter { $0.status == .taken }.count
        let missed = month.filter { $0.status == .missed }
        var s = "In the last 30 days you took \(taken) of \(month.count) doses (\(adherence30)%)."
        // Which dose is missed most often?
        let counts = Dictionary(grouping: missed, by: { "\($0.slot.rawValue) \($0.medName)" }).mapValues(\.count)
        if let top = counts.max(by: { $0.value < $1.value }) {
            s += " The one you miss most is your \(top.key) (\(top.value) times)."
        }
        // The hardest stretch, and how this week compares.
        let sunday = Self.calendar.date(byAdding: .day, value: 1, to: annaWeekend)!
        let weekendMissed = missed.filter { $0.day == annaWeekend || $0.day == sunday }.count
        if weekendMissed > 0 {
            s += " The weekend at Anna's (\(Self.format("d", annaWeekend))-\(Self.format("d MMMM", sunday))) was hardest, with \(weekendMissed) missed."
        }
        let thisWeek = missedThisWeek.count
        let earlier = Double(missed.count - thisWeek) / 23 * 7 // missed per week before this one
        if Double(thisWeek) < earlier { s += " This week is better again." }
        return s
    }

    // MARK: - Calendar

    /// True when Google or Apple Calendar is "connected" in Settings (demo only, nothing is read).
    static var anyCalendarConnected: Bool { CalendarSource.google.isConnected || CalendarSource.apple.isConnected }

    /// The events whose source is shown: the app's own appointments always, the others when connected.
    func visibleEvents(google: Bool, apple: Bool) -> [CalendarEvent] {
        events.filter {
            switch $0.source {
            case .app: true
            case .google: google
            case .apple: apple
            }
        }
    }

    /// How many sample events a calendar "syncs" (its events, 30 days back to 30 days ahead).
    func syncedCount(_ source: CalendarSource) -> Int {
        events.filter { $0.source == source }.count
    }

    /// The upcoming events, soonest first.
    func upcoming(_ count: Int, from now: Date = Date(), in list: [CalendarEvent]? = nil) -> [CalendarEvent] {
        Array((list ?? events).filter { $0.date >= now }.prefix(count))
    }

    func events(on day: Date, in list: [CalendarEvent]? = nil) -> [CalendarEvent] {
        (list ?? events).filter { Self.calendar.isDate($0.date, inSameDayAs: day) }
    }

    /// Short facts for Agatha (the AI), at most 900 characters. Calendar events only when a calendar is connected.
    var summaryForAgatha: String { summaryForAgatha(includeCalendar: Self.anyCalendarConnected) }

    func summaryForAgatha(includeCalendar: Bool) -> String {
        let missed = missedThisWeek.map { "\(Self.weekdayName($0.day)) \($0.slot.rawValue) \($0.medName)" }
        let recentMoods = moods.prefix(3).map { "\(Self.shortDate($0.date)): \($0.mood.label.lowercased()), \"\($0.text)\"" }
        let list = includeCalendar ? events : events.filter(\.fromPlan)
        let next = list.filter { $0.date >= today && $0.kind != .social }.prefix(4).enumerated().map { i, e in
            // What to bring, for the next two medical appointments.
            let bring = i < 2 ? e.note.flatMap(Self.bringText).map { " (bring \($0))" } ?? "" : ""
            return "\(Self.shortDate(e.date)) \(Self.timeText(e.date)) \(e.title)\(bring)"
        }
        var parts = [
            "Doses taken: \(adherence7)% last 7 days, \(adherence30)% last 30 days.",
            "Missed this week: \(missed.isEmpty ? "none" : missed.joined(separator: "; ")).",
            "Pattern: evening Metformin is the dose most often missed; mornings are reliable.",
            "Recent notes: \(recentMoods.joined(separator: " | "))",
        ]
        if includeCalendar {
            parts.append("Coming up: \(next.joined(separator: "; ")). Weekly: choir Wednesdays 17:00, Anna visits Sundays 15:00.")
            if let gp = events.last(where: { $0.kind == .doctor && $0.date < today }), let note = gp.note {
                parts.insert("Last GP visit \(Self.shortDate(gp.date)): \(note)", at: 3)
            }
        } else {
            parts.append("Coming up (appointments saved in the app; no calendar connected): \(next.isEmpty ? "none" : next.joined(separator: "; ")).")
        }
        var text = parts.joined(separator: " ")
        if text.count > 900 { text = String(text.prefix(897)) + "..." }
        return text
    }

    /// "insurance card, glasses" from a note like "... Bring your blood pressure diary and insurance card." or "Bring: X. ..."
    private static func bringText(_ note: String) -> String? {
        for marker in ["Bring: ", "Bring "] {
            guard let range = note.range(of: marker) else { continue }
            let rest = note[range.upperBound...]
            return String(rest.prefix { $0 != "." })
        }
        return nil
    }
}
