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
    var type: String // mark_taken
    var slot: String?
    var names: [String]?
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
