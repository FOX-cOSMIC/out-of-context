import SwiftUI

/// The whole app state: the conversation, the saved plan, the profile and the skills practised.
@MainActor
final class ChatModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published private(set) var plan = Plan()
    @Published private(set) var profile = Profile()
    @Published private(set) var takenToday: [String: Bool] = [:]
    @Published private(set) var skills: Set<Skill> = []
    @Published var isRecording = false
    @Published var isBusy = false
    @Published private(set) var isSpeaking = false
    @Published var status = ""
    @Published var lastLearned: Skill?
    /// First launch: show the big "Start" button instead of a greeting.
    @Published private(set) var showWelcome = false
    /// Hands-free call: speak, listen, send, repeat, until "End call".
    @Published private(set) var isCallMode = false

    private let api = APIClient()
    private let recorder = VoiceRecorder()
    private let speaker = Speaker()
    private var silenceWatch: Task<Void, Never>?
    private var speakToken: UUID?
    /// Set when the profile is saved during the call: hang up after the reply is spoken.
    private var endCallAfterReply = false

    static let startMessage = "(The user opened the app for the first time and tapped Start.)"

    // Listening in a call (tuned by ear; levels are AVAudioRecorder averagePower in dBFS).
    private enum Listen {
        static let pollEvery: Duration = .milliseconds(100)
        static let quietAfterSpeech: TimeInterval = 1.5 // stop this long after the user stops talking
        static let maxLength: TimeInterval = 30
        static let giveUpIfSilent: TimeInterval = 8
        static let minSpeechLevel: Float = -35 // quiet room: louder than this counts as talking
        static let aboveNoise: Float = 10      // noisy room: must be this much louder than the quietest moment
        static let maxSpeechLevel: Float = -20 // never demand more than this, even in a loud room
    }

    init() {
        load()
        if profile.name.isEmpty {
            showWelcome = true
        } else {
            let rest = plan.medications.isEmpty
                ? "Show me a photo of your medication plan, or just talk to me."
                : "Ask me what to take today, or show me a new letter."
            messages = [ChatMessage(role: .assistant, text: "Hello again, \(profile.name)! \(rest)")]
        }
    }

    /// Nothing is being recorded, written down or answered right now.
    var canSend: Bool { !isBusy && !isRecording }

    // MARK: - The "getting to know you" call

    /// The user tapped Start on the welcome screen.
    func startOnboarding() {
        guard showWelcome, canSend else { return }
        showWelcome = false
        isCallMode = true
        endCallAfterReply = false
        // Ask for the microphone now, while Claude is thinking of the first question.
        Task { _ = await recorder.requestPermission() }
        messages.append(ChatMessage(role: .user, text: Self.startMessage, hidden: true))
        isBusy = true // block other input right away, before the task starts
        Task { await askCompanion() }
    }

    /// Start a hands-free call later on (the phone button at the top).
    func startCall() {
        guard !isCallMode, canSend else { return }
        isCallMode = true
        endCallAfterReply = false
        startRecording()
    }

    func endCall() {
        isCallMode = false
        endCallAfterReply = false
        silenceWatch?.cancel()
        if isRecording {
            recorder.cancel()
            isRecording = false
        }
        speaker.stop()
        status = ""
    }

    // MARK: - Talking

    func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    private func startRecording() {
        guard canSend else { return }
        speaker.stop()
        Task {
            guard await recorder.requestPermission() else {
                status = "Please allow the microphone in Settings to talk to me."
                return
            }
            guard canSend else { return } // something else started while we waited
            do {
                try recorder.start()
                isRecording = true
                if isCallMode {
                    status = ""
                    watchForSilence()
                } else {
                    status = "I'm listening… tap again when you're done."
                }
            } catch {
                status = "The microphone did not start. Please try again."
            }
        }
    }

    /// In a call: stop by itself when the user has finished talking.
    private func watchForSilence() {
        silenceWatch?.cancel()
        silenceWatch = Task { [weak self] in
            let started = Date()
            var heardSpeech = false
            var quietSince: Date?
            var quietest: Float? // the room's background noise, learned while listening
            while !Task.isCancelled {
                try? await Task.sleep(for: Listen.pollEvery)
                guard let self, self.isRecording, !Task.isCancelled else { return }
                let now = Date()
                let level = self.recorder.currentLevel()
                // The very first meter readings can be -160 (no signal yet): don't learn from those.
                if level > -100 { quietest = min(quietest ?? level, level) }
                let noise = quietest ?? -60
                let speechLevel = min(max(Listen.minSpeechLevel, noise + Listen.aboveNoise), Listen.maxSpeechLevel)
                if level > speechLevel {
                    heardSpeech = true
                    quietSince = nil
                } else if heardSpeech {
                    let since = quietSince ?? now
                    quietSince = since
                    if now.timeIntervalSince(since) >= Listen.quietAfterSpeech {
                        self.stopRecording()
                        return
                    }
                }
                let elapsed = now.timeIntervalSince(started)
                if elapsed >= Listen.maxLength {
                    self.stopRecording()
                    return
                }
                if !heardSpeech && elapsed >= Listen.giveUpIfSilent {
                    self.recorder.cancel()
                    self.isRecording = false
                    self.status = "Tap to talk when you're ready"
                    return
                }
            }
        }
    }

    private func stopRecording() {
        guard isRecording else { return }
        silenceWatch?.cancel()
        let file = recorder.stop()
        isRecording = false
        isBusy = true
        status = "Writing down what you said…"
        Task {
            do {
                let text = try await api.transcribe(audioFile: file)
                isBusy = false
                guard !text.isEmpty else {
                    status = isCallMode ? "Tap to talk when you're ready" : "I did not hear anything. Please try again."
                    return
                }
                await userSays(text: text, image: nil)
            } catch {
                isBusy = false
                status = error.localizedDescription
                _ = await speak(error.localizedDescription)
            }
        }
    }

    // MARK: - Sending

    /// Typed text or a photo from the screen. Ignored while something else is going on.
    func send(text: String, image: UIImage? = nil) async {
        guard canSend else { return }
        await userSays(text: text, image: image)
    }

    private func userSays(text: String, image: UIImage?) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || image != nil else { return }
        speaker.stop()
        if messages.contains(where: { $0.role == .user && !$0.hidden }) { learn(.followUp) }
        learn(image != nil ? .photo : .ownWords)
        messages.append(ChatMessage(role: .user, text: trimmed, image: image))
        await askCompanion()
    }

    /// The user answered a "Here is what I read" card.
    func answer(messageID: UUID, cardIndex: Int, yes: Bool) async {
        guard canSend,
              let m = messages.firstIndex(where: { $0.id == messageID }),
              messages[m].answers[cardIndex] == nil else { return }
        messages[m].answers[cardIndex] = yes
        let card = messages[m].cards[cardIndex]
        if yes {
            if let meds = card.medications {
                plan.medications = Self.addingNew(meds, to: card.replaces_plan == true ? [] : plan.medications)
            }
            if let appts = card.appointments { plan.appointments = Self.addingNew(appts, to: plan.appointments) }
            save()
        }
        learn(.checked)
        speaker.stop()
        messages.append(ChatMessage(role: .user, text: yes ? "Yes, that's right." : "No, that's not right."))
        await askCompanion()
    }

    /// Appends only items whose id is not in the list yet (the list shows them by id).
    private static func addingNew<T: Identifiable>(_ items: [T], to list: [T]) -> [T] where T.ID == String {
        var result = list
        for item in items where !result.contains(where: { $0.id == item.id }) {
            result.append(item)
        }
        return result
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
        Task { _ = await speak(text) }
    }

    func deleteAllData() {
        endCall()
        plan = Plan()
        profile = Profile()
        takenToday = [:]
        skills = []
        save()
        messages = []
        showWelcome = true
    }

    /// Only one of these runs at a time: every way in checks `canSend` first.
    private func askCompanion() async {
        isBusy = true
        status = "Thinking…"
        let reply: ChatReply
        do {
            reply = try await api.chat(.init(
                history: historyForServer(),
                plan: plan,
                taken: takenToday,
                today: Date().formatted(date: .complete, time: .shortened),
                skills: skills.map(\.rawValue),
                profile: profile
            ))
        } catch {
            isBusy = false
            status = ""
            messages.append(ChatMessage(role: .assistant, text: error.localizedDescription))
            _ = await speak(error.localizedDescription)
            if isCallMode { status = "Tap to talk when you're ready" }
            return
        }
        apply(reply.actions)
        messages.append(ChatMessage(role: .assistant, text: reply.reply, cards: reply.cards))
        isBusy = false
        status = ""
        let finished = reply.reply.isEmpty ? true : await speak(reply.reply)

        guard isCallMode else { return }
        if endCallAfterReply {
            // Wait for the goodbye to be heard; if the user interrupted, they are taking over anyway.
            endCall()
        } else if finished && canSend {
            try? await Task.sleep(for: .milliseconds(300)) // let the speaker go quiet first
            if isCallMode && canSend && !isSpeaking { startRecording() }
        }
    }

    /// Speaks and returns when done: true if it finished, false if something stopped it.
    private func speak(_ text: String) async -> Bool {
        let token = UUID()
        speakToken = token
        isSpeaking = true
        let finished = await speaker.say(text, rate: profile.prefersSlowSpeech ? 140 : nil, using: api)
        if speakToken == token { isSpeaking = false }
        return finished
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
        for action in actions {
            switch action.type {
            case "mark_taken":
                guard let slot = action.slot, let names = action.names else { continue }
                for name in names {
                    // Claude may say "Ramipril" for "Ramipril (Ramipril-ratio)": match loosely.
                    let spoken = name.lowercased()
                    let med = plan.medications.first { $0.name.lowercased() == spoken }
                        ?? plan.medications.first { $0.name.lowercased().contains(spoken) || spoken.contains($0.name.lowercased()) }
                    takenToday[takenKey(med?.name ?? name, Slot(rawValue: slot) ?? .morning)] = true
                }
            case "save_profile":
                guard let newProfile = action.profile else { continue }
                profile = newProfile
                if isCallMode && !newProfile.name.isEmpty { endCallAfterReply = true }
            default:
                continue
            }
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
        defaults.set(try? JSONEncoder().encode(profile), forKey: "profile")
        defaults.set(try? JSONEncoder().encode(takenToday), forKey: "taken-\(todayKey)")
        defaults.set(try? JSONEncoder().encode(Array(skills)), forKey: "skills")
    }

    private func load() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "plan"), let saved = try? JSONDecoder().decode(Plan.self, from: data) {
            plan = saved
        }
        if let data = defaults.data(forKey: "profile"), let saved = try? JSONDecoder().decode(Profile.self, from: data) {
            profile = saved
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
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1 // real pixels, not 3x screen points
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        let jpeg = resized.jpegData(compressionQuality: 0.85) ?? Data()
        return "data:image/jpeg;base64,\(jpeg.base64EncodedString())"
    }
}
