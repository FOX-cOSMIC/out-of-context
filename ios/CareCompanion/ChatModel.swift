import SwiftUI

/// The whole app state: the conversation, the saved plan, and the skills practised.
@MainActor
final class ChatModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published private(set) var plan = Plan()
    @Published private(set) var takenToday: [String: Bool] = [:]
    @Published private(set) var skills: Set<Skill> = []
    @Published var isRecording = false
    @Published var isBusy = false
    @Published var status = ""
    @Published var lastLearned: Skill?

    private let api = APIClient()
    private let recorder = VoiceRecorder()
    private let speaker = Speaker()

    init() {
        load()
        let greeting = plan.medications.isEmpty
            ? "Hello! I'm your Care Companion. Show me a photo of your medication plan, or just talk to me."
            : "Hello again! Ask me what to take today, or show me a new letter."
        messages = [ChatMessage(role: .assistant, text: greeting)]
    }

    // MARK: - Talking

    func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    private func startRecording() {
        speaker.stop()
        Task {
            guard await recorder.requestPermission() else {
                status = "Please allow the microphone in Settings to talk to me."
                return
            }
            do {
                try recorder.start()
                isRecording = true
                status = "I'm listening… tap again when you're done."
            } catch {
                status = "The microphone did not start. Please try again."
            }
        }
    }

    private func stopRecording() {
        let file = recorder.stop()
        isRecording = false
        isBusy = true
        status = "Writing down what you said…"
        Task {
            defer { isBusy = false }
            do {
                let text = try await api.transcribe(audioFile: file)
                guard !text.isEmpty else {
                    status = "I did not hear anything. Please try again."
                    return
                }
                await send(text: text)
            } catch {
                status = error.localizedDescription
            }
        }
    }

    // MARK: - Sending

    func send(text: String, image: UIImage? = nil) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || image != nil else { return }
        speaker.stop()
        if messages.contains(where: { $0.role == .user }) { learn(.followUp) }
        learn(image != nil ? .photo : .ownWords)
        messages.append(ChatMessage(role: .user, text: trimmed, image: image))
        await askCompanion()
    }

    /// The user answered a "Here is what I read" card.
    func answer(messageID: UUID, cardIndex: Int, yes: Bool) async {
        guard let m = messages.firstIndex(where: { $0.id == messageID }),
              messages[m].answers[cardIndex] == nil else { return }
        messages[m].answers[cardIndex] = yes
        let card = messages[m].cards[cardIndex]
        if yes {
            if let meds = card.medications {
                plan.medications = card.replaces_plan == true ? meds : plan.medications + meds
            }
            if let appts = card.appointments { plan.appointments += appts }
            save()
        }
        learn(.checked)
        messages.append(ChatMessage(role: .user, text: yes ? "Yes, that's right." : "No, that's not right."))
        await askCompanion()
    }

    func toggleTaken(_ med: Medication, slot: Slot) {
        let key = takenKey(med.name, slot)
        takenToday[key] = !(takenToday[key] ?? false)
        save()
    }

    func isTaken(_ med: Medication, slot: Slot) -> Bool {
        takenToday[takenKey(med.name, slot)] ?? false
    }

    func repeatAloud(_ text: String) {
        Task { await speaker.say(text, using: api) }
    }

    func deleteAllData() {
        plan = Plan()
        takenToday = [:]
        skills = []
        save()
        messages = [ChatMessage(role: .assistant, text: "Everything is deleted. Show me a photo of your medication plan to start again.")]
    }

    private func askCompanion() async {
        isBusy = true
        status = "Thinking…"
        defer { isBusy = false }
        do {
            let reply = try await api.chat(.init(
                history: historyForServer(),
                plan: plan,
                taken: takenToday,
                today: Date().formatted(date: .complete, time: .shortened),
                skills: skills.map(\.rawValue)
            ))
            apply(reply.actions)
            messages.append(ChatMessage(role: .assistant, text: reply.reply, cards: reply.cards))
            status = ""
            if !reply.reply.isEmpty { await speaker.say(reply.reply, using: api) }
        } catch {
            messages.append(ChatMessage(role: .assistant, text: error.localizedDescription))
            status = ""
        }
    }

    /// Only the newest photo travels as image data; older ones become a short note.
    private func historyForServer() -> [APIClient.HistoryItem] {
        let newestImage = messages.lastIndex(where: { $0.image != nil })
        return messages.enumerated().map { index, m in
            var image: String?
            if let picture = m.image {
                image = index == newestImage ? Self.dataURL(for: picture) : "earlier-photo"
            }
            var text = m.text
            if m.role == .assistant, !m.cards.isEmpty {
                text += " [Shown on screen: \(m.cards.map(\.type).joined(separator: ", "))]"
            }
            return .init(role: m.role.rawValue, text: text, image: image)
        }
    }

    private func apply(_ actions: [ChatAction]) {
        for action in actions where action.type == "mark_taken" {
            guard let slot = action.slot, let names = action.names else { continue }
            for name in names { takenToday[takenKey(name, Slot(rawValue: slot) ?? .morning)] = true }
        }
        save()
    }

    private func learn(_ skill: Skill) {
        guard !skills.contains(skill) else { return }
        skills.insert(skill)
        lastLearned = skill
        save()
    }

    // MARK: - Saving on this phone only

    private func takenKey(_ name: String, _ slot: Slot) -> String {
        "\(slot.rawValue):\(name.lowercased())"
    }

    private var todayKey: String { Date().formatted(.iso8601.year().month().day()) }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(try? JSONEncoder().encode(plan), forKey: "plan")
        defaults.set(try? JSONEncoder().encode(takenToday), forKey: "taken-\(todayKey)")
        defaults.set(try? JSONEncoder().encode(Array(skills)), forKey: "skills")
    }

    private func load() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "plan"), let saved = try? JSONDecoder().decode(Plan.self, from: data) {
            plan = saved
        }
        if let data = defaults.data(forKey: "taken-\(todayKey)"),
           let saved = try? JSONDecoder().decode([String: Bool].self, from: data) {
            takenToday = saved
        }
        if let data = defaults.data(forKey: "skills"), let saved = try? JSONDecoder().decode([Skill].self, from: data) {
            skills = Set(saved)
        }
    }

    /// Shrinks a photo to max 1600 px and encodes it as a JPEG data URL.
    static func dataURL(for image: UIImage) -> String {
        let longest = max(image.size.width, image.size.height)
        let scale = min(1, 1600 / max(longest, 1))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: size).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        let jpeg = resized.jpegData(compressionQuality: 0.85) ?? Data()
        return "data:image/jpeg;base64,\(jpeg.base64EncodedString())"
    }
}
