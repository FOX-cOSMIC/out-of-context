import Foundation
import UIKit

// MARK: - The saved plan (kept only on this phone)

struct Times: Codable, Hashable {
    var morning: String
    var midday: String
    var evening: String
    var night: String

    func dose(for slot: Slot) -> String {
        switch slot {
        case .morning: morning
        case .midday: midday
        case .evening: evening
        case .night: night
        }
    }
}

struct Medication: Codable, Hashable, Identifiable {
    var name: String
    var strength: String
    var purpose: String
    var times: Times
    var instructions: String
    var id: String { "\(name)|\(strength)" }
}

struct Appointment: Codable, Hashable, Identifiable {
    var title: String
    var date: String
    var time: String
    var place: String
    var bring: String
    var preparation: String
    var id: String { "\(title)|\(date)|\(time)" }
}

struct Plan: Codable {
    var medications: [Medication] = []
    var appointments: [Appointment] = []
}

/// What the "getting to know you" call learned about the user. "" = unknown.
struct Profile: Codable, Equatable {
    var name = ""
    var address_as = ""
    var wake_time = ""
    var breakfast_time = ""
    var lunch_time = ""
    var dinner_time = ""
    var bed_time = ""
    var hearing = ""
    var eyesight = ""
    var tech_comfort = ""
    var helper_name = ""
    var helper_relation = ""
    var doctor_name = ""

    init() {}

    /// Missing fields become "" so an older or partial profile still loads.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func field(_ key: CodingKeys) -> String { ((try? c.decodeIfPresent(String.self, forKey: key)) ?? nil) ?? "" }
        name = field(.name)
        address_as = field(.address_as)
        wake_time = field(.wake_time)
        breakfast_time = field(.breakfast_time)
        lunch_time = field(.lunch_time)
        dinner_time = field(.dinner_time)
        bed_time = field(.bed_time)
        hearing = field(.hearing)
        eyesight = field(.eyesight)
        tech_comfort = field(.tech_comfort)
        helper_name = field(.helper_name)
        helper_relation = field(.helper_relation)
        doctor_name = field(.doctor_name)
    }

    /// True when the user said hearing or eyesight is difficult: then we speak more slowly.
    var prefersSlowSpeech: Bool {
        let words = ["poor", "hard", "bad", "difficult", "not good"]
        let said = (hearing + " " + eyesight).lowercased()
        return words.contains { said.contains($0) }
    }
}

enum Slot: String, CaseIterable, Codable {
    case morning, midday, evening, night
    var label: String { rawValue.capitalized }
}

// MARK: - What the server sends back

/// Something Claude puts on screen inside the conversation.
struct Card: Codable, Hashable {
    var type: String // schedule | appointments | confirm_medications | confirm_appointments
    var slot: String?
    var replaces_plan: Bool?
    var medications: [Medication]?
    var unclear: [String]?
    var appointments: [Appointment]?
}

/// Something Claude asks the app to do, e.g. tick off medicines.
struct ChatAction: Codable {
    var type: String // mark_taken | save_profile | open_screen | save_note | save_document
    var slot: String?
    var names: [String]?
    var profile: Profile?
    var screen: String? // open_screen: home | pills | scan | notes | sos
    var title: String?  // save_note, save_document
    var text: String?   // save_note
    var kind: String?   // save_note: note | doctor_questions | feeling
    var summary: String? // save_document
}

// MARK: - Notes and papers Agatha keeps (only on this phone)

/// A note Agatha wrote down for the user, e.g. questions for the doctor.
struct SavedNote: Codable, Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var title: String
    var text: String
    var kind: String // note | doctor_questions | feeling

    /// "For Dr Hoffmann", "How I felt", "Note".
    func kindLabel(doctor: String) -> String {
        switch kind {
        case "doctor_questions": doctor.isEmpty ? "For my doctor" : "For \(doctor)"
        case "feeling": "How I felt"
        default: "Note"
        }
    }
}

/// A photo of a letter or form the user asked Agatha to keep, saved as a JPEG in the app's Documents folder.
struct SavedPaper: Codable, Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var title: String
    var summary: String
    var fileName: String

    var fileURL: URL {
        URL.documentsDirectory.appending(path: fileName)
    }
}

struct ChatReply: Codable {
    var reply: String
    var cards: [Card]
    var actions: [ChatAction]
}

// MARK: - The conversation on screen

struct ChatMessage: Identifiable {
    enum Role: String { case user, assistant }
    let id = UUID()
    var role: Role
    var text: String
    var image: UIImage? = nil
    var cards: [Card] = []
    /// For confirm cards: index -> true (Yes) / false (No) once answered.
    var answers: [Int: Bool] = [:]
    /// Sent to the server but not shown (e.g. "the user tapped Start").
    var hidden = false
    /// An app error shown as Agatha's bubble (e.g. "I can't reach the helper"): never sent to the server.
    var isError = false
}

// MARK: - AI skills the user practises

enum Skill: String, CaseIterable, Codable {
    case ownWords = "own_words"
    case photo
    case checked
    case followUp = "follow_up"

    var label: String {
        switch self {
        case .ownWords: "Talk in your own words"
        case .photo: "Show a photo"
        case .checked: "Check the answer"
        case .followUp: "Ask a follow-up"
        }
    }

    var icon: String {
        switch self {
        case .ownWords: "mic.fill"
        case .photo: "camera.fill"
        case .checked: "checkmark.shield.fill"
        case .followUp: "bubble.left.and.bubble.right.fill"
        }
    }
}
