import Foundation

/// Pills left at home per medicine: the arithmetic behind "23 left · about 11 days".
/// The counts themselves live in ChatModel.stock (key = medicine name).
enum PillStock {
    /// Fewer days left than this counts as "running low".
    static let lowDays = 7

    /// How many tablets one dose uses: "1" -> 1, "2" -> 2, "1/2" -> 0.5, "1,5" -> 1.5; empty, "0" or "-" -> 0.
    static func amount(_ raw: String) -> Double {
        let dose = raw.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        if let n = Double(dose) { return max(0, n) }
        let parts = dose.split(separator: "/").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        if parts.count == 2, parts[1] > 0 { return parts[0] / parts[1] }
        return 0
    }

    /// Whole tablets taken out of the pack for one dose (a half tablet still takes one out).
    static func tabletsUsed(_ raw: String) -> Int {
        let n = amount(raw)
        return n > 0 ? Int(n.rounded(.up)) : 0
    }

    /// Tablets per day over all times of day.
    static func perDay(_ med: Medication) -> Double {
        Slot.allCases.reduce(0) { $0 + amount(med.times.dose(for: $1)) }
    }

    /// Whole days the pills last, or nil when the medicine has no daily dose.
    static func daysLeft(count: Int, med: Medication) -> Int? {
        let daily = perDay(med)
        guard daily > 0 else { return nil }
        return Int((Double(max(0, count)) / daily).rounded(.down))
    }

    static func isLow(count: Int, med: Medication) -> Bool {
        guard let days = daysLeft(count: count, med: med) else { return false }
        return days < lowDays
    }

    /// "23 left · about 11 days".
    static func label(count: Int, med: Medication) -> String {
        guard let days = daysLeft(count: count, med: med) else { return "\(count) left" }
        return "\(count) left · about \(days) \(days == 1 ? "day" : "days")"
    }
}
