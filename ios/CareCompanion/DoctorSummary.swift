import UIKit
import PDFKit

/// "Summary for Dr Hoffmann": a one- or two-page A4 PDF Agatha makes for a doctor's visit
/// (create_document tool). Built only from what is on this phone; nothing is sent anywhere.
struct DoctorSummary {
    var patientName: String
    var doctorName: String
    var date: Date
    var medications: [Medication]
    var stock: [String: Int]
    var history: DemoHistory
    var notes: [SavedNote]
    var appointments: [Appointment]
    /// Calendar events (pharmacy, blood test) only when a calendar is connected in Settings.
    var includeCalendar: Bool

    // MARK: - Content

    private enum Block {
        case heading(String)
        case line(String)
        case bullet(String)
        case warning(String)
    }

    private var doctor: String { doctorName.isEmpty ? "my doctor" : doctorName }

    var title: String { "Summary for \(doctor) — \(Self.format("d MMMM yyyy", date))" }

    private var blocks: [Block] {
        var b: [Block] = []
        b.append(.line("Made with the Agatha app on \(Self.format("EEEE d MMMM yyyy, HH:mm", date)). Please check it against the medication plan."))

        b.append(.heading("Current medicines"))
        if medications.isEmpty { b.append(.line("No medicines saved in the app.")) }
        for med in medications {
            let name = [med.name, med.strength].filter { !$0.isEmpty }.joined(separator: " ")
            let times = Slot.allCases.compactMap { slot -> String? in
                let dose = med.times.dose(for: slot).trimmingCharacters(in: .whitespaces)
                return dose.isEmpty || dose == "0" || dose == "-" ? nil : "\(slot.label.lowercased()) \(dose)"
            }.joined(separator: ", ")
            var text = "\(name): \(times.isEmpty ? "no fixed times" : times)"
            if !med.purpose.isEmpty { text += " (\(med.purpose))" }
            if !med.instructions.isEmpty { text += "; \(med.instructions)" }
            b.append(.bullet(text))
        }

        b.append(.heading("Tablets left at home"))
        var anyStock = false
        for med in medications {
            guard let count = stock[med.name] else { continue }
            anyStock = true
            let text = "\(med.name): \(PillStock.label(count: count, med: med))"
            if PillStock.isLow(count: count, med: med) {
                b.append(.warning("\(text) — running low, a new prescription is needed"))
            } else {
                b.append(.bullet(text))
            }
        }
        if !anyStock { b.append(.line("No counts saved.")) }

        b.append(.heading("Taking the medicines"))
        let week = history.doses(lastDays: 7)
        let month = history.doses(lastDays: 30)
        b.append(.bullet("Last 7 days: \(week.filter { $0.status == .taken }.count) of \(week.count) doses taken (\(history.adherence7)%)."))
        b.append(.bullet("Last 30 days: \(month.filter { $0.status == .taken }.count) of \(month.count) doses taken (\(history.adherence30)%)."))
        let missed = history.missedThisWeek
        if missed.isEmpty {
            b.append(.bullet("No missed doses in the last 7 days."))
        } else {
            let list = missed.map { "\(DemoHistory.shortDate($0.day)) \($0.slot.rawValue) \($0.medName)" }
            b.append(.bullet("Missed in the last 7 days: \(list.joined(separator: "; "))."))
        }
        let missedMonth = month.filter { $0.status == .missed }
        let counts = Dictionary(grouping: missedMonth, by: { "\($0.slot.rawValue) \($0.medName)" }).mapValues(\.count)
        if let top = counts.max(by: { $0.value < $1.value }) {
            b.append(.bullet("Most often missed: \(top.key) (\(top.value) times in 30 days)."))
        }

        let questions = notes.filter { $0.kind == "doctor_questions" }
        b.append(.heading("My questions for \(doctor)"))
        if questions.isEmpty { b.append(.line("No questions written down yet.")) }
        for note in questions { b.append(.bullet("\(note.title): \(note.text)")) }

        b.append(.heading("How I have been feeling"))
        for note in notes.filter({ $0.kind == "feeling" }).reversed() {
            b.append(.bullet("\(Self.format("EEE d MMM", note.date)): \(note.title). \(note.text)"))
        }
        for mood in history.moods.prefix(5) {
            b.append(.bullet("\(DemoHistory.shortDate(mood.date)) (\(mood.mood.label.lowercased())): \(mood.text)"))
        }

        b.append(.heading("Coming up"))
        // Saved appointments plus (when a calendar is connected) pharmacy and doctor dates, soonest first.
        var upcoming: [(when: Date, text: String)] = appointments.map { appt in
            let when = DemoHistory.event(for: appt)?.date ?? .distantFuture
            let text = "\(appt.date), \(appt.time): \(appt.title)" + (appt.place.isEmpty ? "" : ", \(appt.place)")
                + (appt.bring.isEmpty ? "" : ". Bring: \(appt.bring)")
            return (when, text)
        }
        if includeCalendar {
            let calendarEvents = history.events.filter {
                $0.date >= date && !$0.fromPlan && ($0.kind == .doctor || $0.kind == .pharmacy)
            }
            upcoming += calendarEvents.prefix(3).map {
                ($0.date, "\(DemoHistory.shortDate($0.date)), \(DemoHistory.timeText($0.date)): \($0.title), \($0.place)")
            }
        }
        upcoming.sort { $0.when < $1.when }
        if upcoming.isEmpty { b.append(.line("No appointments saved.")) }
        for item in upcoming { b.append(.bullet(item.text)) }
        return b
    }

    // MARK: - PDF

    /// A4 in points.
    static let pageSize = CGSize(width: 595.2, height: 841.8)
    private static let margin: CGFloat = 50

    private static let ink = UIColor(red: 0.12, green: 0.11, blue: 0.20, alpha: 1)
    private static let purple = UIColor(red: 0.42, green: 0.30, blue: 0.85, alpha: 1)
    private static let orange = UIColor(red: 0.75, green: 0.36, blue: 0.0, alpha: 1)

    func pdfData() -> Data {
        let bounds = CGRect(origin: .zero, size: Self.pageSize)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: {
            let f = UIGraphicsPDFRendererFormat()
            f.documentInfo = [kCGPDFContextTitle as String: title, kCGPDFContextCreator as String: "Agatha"]
            return f
        }())
        let width = Self.pageSize.width - 2 * Self.margin
        let bottom = Self.pageSize.height - Self.margin
        return renderer.pdfData { context in
            var y: CGFloat = 0
            var page = 0
            func newPage() {
                context.beginPage()
                page += 1
                y = Self.margin
                let footer = NSAttributedString(string: "\(patientName) · \(title) · page \(page)", attributes: [
                    .font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.gray,
                ])
                footer.draw(at: CGPoint(x: Self.margin, y: Self.pageSize.height - Self.margin + 18))
            }
            /// Draws text at the current position, starting a new page when it does not fit.
            func draw(_ text: NSAttributedString, indent: CGFloat = 0, spacingAfter: CGFloat) {
                let w = width - indent
                let h = ceil(text.boundingRect(with: CGSize(width: w, height: .greatestFiniteMagnitude),
                                               options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height)
                if y + h > bottom { newPage() }
                text.draw(with: CGRect(x: Self.margin + indent, y: y, width: w, height: h),
                          options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                y += h + spacingAfter
            }

            newPage()
            draw(Self.text(title, size: 24, weight: .bold, color: Self.purple), spacingAfter: 4)
            draw(Self.text(patientName.isEmpty ? "(name not saved)" : patientName, size: 18, weight: .semibold), spacingAfter: 10)
            for block in blocks {
                switch block {
                case .heading(let s):
                    if y + 70 > bottom { newPage() } // keep a heading with its first line
                    y += 10
                    draw(Self.text(s, size: 19, weight: .bold, color: Self.purple), spacingAfter: 6)
                case .line(let s):
                    draw(Self.text(s, size: 15), spacingAfter: 6)
                case .bullet(let s):
                    draw(Self.text("•  " + s, size: 15), indent: 8, spacingAfter: 5)
                case .warning(let s):
                    draw(Self.text("!  " + s, size: 15, weight: .bold, color: Self.orange), indent: 8, spacingAfter: 5)
                }
            }
        }
    }

    private static func text(_ s: String, size: CGFloat, weight: UIFont.Weight = .regular, color: UIColor = ink) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 3
        style.headIndent = s.hasPrefix("•  ") || s.hasPrefix("!  ") ? 16 : 0
        return NSAttributedString(string: s, attributes: [
            .font: UIFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color,
            .paragraphStyle: style,
        ])
    }

    /// The first page as a picture, for the thumbnail in "My papers".
    static func firstPageImage(pdf data: Data, width: CGFloat = 600) -> UIImage? {
        // Keep the document alive while drawing: a page only holds it weakly.
        guard let document = PDFDocument(data: data), let page = document.page(at: 0) else { return nil }
        let rect = page.bounds(for: .mediaBox)
        let size = CGSize(width: width, height: width * rect.height / max(rect.width, 1))
        let image = page.thumbnail(of: size, for: .mediaBox)
        return withExtendedLifetime(document) { image }
    }

    private static func format(_ pattern: String, _ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = pattern
        return f.string(from: date)
    }
}
