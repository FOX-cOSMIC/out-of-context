import SwiftUI

/// "My week & month": how many pills were taken, a dot per day, and how the user felt.
struct HistoryView: View {
    var history: DemoHistory = .shared
    @Environment(\.dismiss) private var dismiss

    enum Range: String, CaseIterable, Identifiable {
        case week = "Week", month = "Month"
        var id: String { rawValue }
        var days: Int { self == .week ? 7 : 30 }
    }

    @State private var range: Range = .week

    var body: some View {
        let percent = history.adherence(lastDays: range.days)
        let doses = history.doses(lastDays: range.days)
        let taken = doses.filter { $0.status == .taken }.count

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SheetHeader(title: "My week & month", close: { dismiss() })

                Picker("Show", selection: $range) {
                    ForEach(Range.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
                .accessibilityLabel("Show week or month")

                // Ring + plain sentence
                VStack(spacing: 16) {
                    AdherenceRing(percent: percent, caption: "\(taken) of \(doses.count) taken")
                    Text(range == .week ? history.weeklySummary : history.monthlySummary)
                        .font(Theme.Typeface.body(20))
                        .foregroundStyle(Theme.Palette.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Theme.Palette.lavender, in: RoundedRectangle(cornerRadius: 24))

                // Day dots
                VStack(alignment: .leading, spacing: 14) {
                    Text(range == .week ? "The last 7 days" : "The last 30 days")
                        .font(Theme.Typeface.heading(24))
                        .foregroundStyle(Theme.Palette.ink)
                    if range == .week {
                        WeekDots(days: history.days(lastDays: 7))
                    } else {
                        MonthDots(days: history.days(lastDays: 30))
                    }
                    Legend()
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Palette.white, in: RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.Palette.lavenderBorder, lineWidth: 2))

                if range == .week && !history.missedThisWeek.isEmpty {
                    MissedList(missed: history.missedThisWeek)
                }

                // How I felt
                Text("How I felt")
                    .font(Theme.Typeface.heading(26))
                    .foregroundStyle(Theme.Palette.ink)
                    .padding(.top, 4)
                let moods = history.moods.filter {
                    $0.date >= DemoHistory.calendar.date(byAdding: .day, value: -range.days, to: history.today)!
                }
                ForEach(moods) { MoodRow(entry: $0) }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
        }
        .background(Theme.Palette.page.ignoresSafeArea())
    }
}

// MARK: - Header with a big Close button (shared with CalendarView)

struct SheetHeader: View {
    let title: String
    let close: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(Theme.Typeface.heading(30))
                .foregroundStyle(Theme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Button(action: close) {
                Text("Close")
                    .font(Theme.Typeface.heading(20))
                    .foregroundStyle(Theme.Palette.purple)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 52)
                    .background(Theme.Palette.lavender, in: Capsule())
            }
            .accessibilityLabel("Close \(title)")
        }
    }
}

// MARK: - Ring

private struct AdherenceRing: View {
    let percent: Int
    let caption: String

    var body: some View {
        ZStack {
            Circle().stroke(Theme.Palette.white, lineWidth: 16)
            Circle()
                .trim(from: 0, to: CGFloat(percent) / 100)
                .stroke(Theme.Palette.green, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.snappy, value: percent)
            VStack(spacing: 2) {
                Text("\(percent)%")
                    .font(Theme.Typeface.heading(44))
                    .foregroundStyle(Theme.Palette.ink)
                Text(caption)
                    .font(Theme.Typeface.body(17))
                    .foregroundStyle(Theme.Palette.inkSoft)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
        }
        .frame(width: 180, height: 180)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(percent) percent of pills taken, \(caption)")
    }
}

// MARK: - Day dots

private struct DayDot: View {
    let day: DemoHistory.DaySummary
    var size: CGFloat = 40
    var showNumber = true

    var body: some View {
        ZStack {
            Circle().fill(day.allTaken ? Theme.Palette.mint : Theme.Palette.peach)
            Circle().stroke(day.allTaken ? Theme.Palette.green : Theme.Palette.orange, lineWidth: 2.5)
            if showNumber {
                Text("\(DemoHistory.calendar.component(.day, from: day.day))")
                    .font(Theme.Typeface.body(size > 36 ? 17 : 15, weight: .bold))
                    .foregroundStyle(day.allTaken ? Theme.Palette.green : Theme.Palette.orangeText)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(DemoHistory.shortDate(day.day)): " +
                            (day.allTaken ? "all taken" : "\(day.total - day.taken) missed"))
    }
}

private struct WeekDots: View {
    let days: [DemoHistory.DaySummary]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days) { day in
                VStack(spacing: 6) {
                    Text(String(DemoHistory.weekdayName(day.day).prefix(3)))
                        .font(Theme.Typeface.body(16, weight: .bold))
                        .foregroundStyle(Theme.Palette.inkSoft)
                    DayDot(day: day, size: 42)
                    Image(systemName: day.allTaken ? "checkmark" : "exclamationmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(day.allTaken ? Theme.Palette.green : Theme.Palette.orangeText)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

/// 30 days laid out like a calendar (Monday first), so each day sits under its weekday.
private struct MonthDots: View {
    let days: [DemoHistory.DaySummary]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        let lead = days.first.map { (DemoHistory.calendar.component(.weekday, from: $0.day) + 5) % 7 } ?? 0
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(["M", "T", "W", "T", "F", "S", "S"].indices, id: \.self) { i in
                Text(["M", "T", "W", "T", "F", "S", "S"][i])
                    .font(Theme.Typeface.body(16, weight: .bold))
                    .foregroundStyle(Theme.Palette.inkSoft)
            }
            ForEach(0..<lead, id: \.self) { _ in Color.clear.frame(height: 38) }
            ForEach(days) { DayDot(day: $0, size: 38) }
        }
    }
}

private struct Legend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            legendRow(fill: Theme.Palette.mint, stroke: Theme.Palette.green, text: "Green: all pills taken")
            legendRow(fill: Theme.Palette.peach, stroke: Theme.Palette.orange, text: "Orange: some pills missed")
        }
        .padding(.top, 4)
    }

    private func legendRow(fill: Color, stroke: Color, text: String) -> some View {
        HStack(spacing: 10) {
            Circle().fill(fill).overlay(Circle().stroke(stroke, lineWidth: 2.5)).frame(width: 22, height: 22)
            Text(text)
                .font(Theme.Typeface.body(19))
                .foregroundStyle(Theme.Palette.ink)
        }
    }
}

// MARK: - Missed this week

private struct MissedList: View {
    let missed: [DemoHistory.DoseEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Missed this week", systemImage: "exclamationmark.circle.fill")
                .font(Theme.Typeface.heading(22))
                .foregroundStyle(Theme.Palette.orangeText)
            ForEach(missed) { dose in
                Text("\(DemoHistory.weekdayName(dose.day)) \(dose.slot.rawValue): \(dose.medName)")
                    .font(Theme.Typeface.body(19))
                    .foregroundStyle(Theme.Palette.ink)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.peach, in: RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Mood row

private struct MoodRow: View {
    let entry: DemoHistory.MoodEntry

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            IconTile(systemName: entry.mood.icon, color: color, background: Theme.Palette.white, circle: true)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(DemoHistory.shortDate(entry.date)) · \(entry.mood.label)")
                    .font(Theme.Typeface.body(17, weight: .bold))
                    .foregroundStyle(Theme.Palette.inkSoft)
                Text(entry.text)
                    .font(Theme.Typeface.body(20))
                    .foregroundStyle(Theme.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background, in: RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }

    private var color: Color {
        switch entry.mood {
        case .good: Theme.Palette.green
        case .okay: Theme.Palette.orangeDark
        case .notWell: Theme.Palette.purple
        }
    }

    private var background: Color {
        switch entry.mood {
        case .good: Theme.Palette.mint
        case .okay: Theme.Palette.peach
        case .notWell: Theme.Palette.lavenderLight
        }
    }
}

#Preview {
    HistoryView()
}
