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
    /// A call: Agatha speaks, the user answers, repeat, until "End call".
    /// The user taps to answer, unless "Hands-free" is on in Settings.
    @Published private(set) var isCallMode = false
    /// The words heard so far while the user is talking (live transcription); nil when not listening live.
    @Published private(set) var liveText: String?
    /// Notes Agatha wrote down (oldest first) and papers she kept, saved on this phone.
    @Published private(set) var notes: [SavedNote] = []
    @Published private(set) var papers: [SavedPaper] = []
    /// A screen Agatha opened (open_screen); RootView switches the tab and clears it.
    @Published var pendingTab: AppTab?

    private let api = APIClient()
    private let recorder = VoiceRecorder()
    private let live = SpeechTranscriber() // Mac (Whisper) or iPhone speech, per Settings
    /// The current recording is written down live on the phone (false: the Whisper recorder is used).
    private var isLive = false
    /// Live transcription broke down on this phone: use Whisper until the app restarts.
    private var preferWhisper = false
    private let speaker = Speaker()
    private var silenceWatch: Task<Void, Never>?
    private var speakToken: UUID?
    /// Set when the profile is saved during the call: hang up after the reply is spoken.
    private var endCallAfterReply = false

    static let startMessage = "(The user opened the app for the first time and tapped Start.)"

    // Listening in a call (tuned by ear; levels are microphone loudness in dBFS).
    private enum Listen {
        static let pollEvery: Duration = .milliseconds(100)
        static let quietAfterSpeech: TimeInterval = 1.5 // Whisper path: stop this long after the user stops talking
        static let quietWords: TimeInterval = 1.5    // live: stop when no new words came for this long...
        static let quietWordsMax: TimeInterval = 3    // ...once the room is quiet too, or after this long regardless
        static let liveFailedEarly: TimeInterval = 2  // live recognition that dies this fast is broken: use Whisper
        static let maxLength: TimeInterval = 30
        static let giveUpIfSilent: TimeInterval = 8
        static let minSpeechLevel: Float = -35 // quiet room: louder than this counts as talking
        static let aboveNoise: Float = 10      // noisy room: must be this much louder than the quietest moment
        static let maxSpeechLevel: Float = -20 // never demand more than this, even in a loud room
    }

    init() {
        load()
        // Demo: no "getting to know you" call; start as the predefined person.
        if profile.name.isEmpty {
            profile = DemoPerson.profile
            if plan.medications.isEmpty { plan = DemoPerson.plan }
            save()
        }
        showWelcome = false
        let rest = plan.medications.isEmpty
            ? "Show me a photo of your medication plan, or just talk to me."
            : "Ask me what to take today, or show me a new letter."
        messages = [ChatMessage(role: .assistant, text: "Hello again\(greetingName)! \(rest)")]
    }

    /// ", Maggie" (how they like to be called), or "" if unknown.
    private var greetingName: String {
        let name = profile.address_as.isEmpty ? profile.name : profile.address_as
        return name.isEmpty ? "" : ", \(name)"
    }

    /// Nothing is being recorded, written down or answered right now.
    var canSend: Bool { !isBusy && !isRecording }

    /// Settings → Hands-free: listen again by herself after speaking (default off: tap to answer).
    private var handsFree: Bool { UserDefaults.standard.bool(forKey: "handsFree") }

    /// What the call shows when it is the user's turn.
    var yourTurnStatus: String {
        handsFree ? "Tap to talk when you're ready" : "Your turn: tap the button to answer"
    }

    // MARK: - The "getting to know you" call

    /// The user tapped Start on the welcome screen.
    func startOnboarding() {
        guard showWelcome, canSend else { return }
        showWelcome = false
        isCallMode = true
        endCallAfterReply = false
        // Ask for the microphone and speech recognition now, while Claude is thinking of the first question.
        Task { _ = await requestVoicePermissions() }
        messages.append(ChatMessage(role: .user, text: Self.startMessage, hidden: true))
        isBusy = true // block other input right away, before the task starts
        Task { await askCompanion() }
    }

    /// Start a call later on (the phone button at the top). The user tapped, so listen right away.
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
            if isLive { live.cancel() } else { recorder.cancel() }
            isRecording = false
        }
        liveText = nil
        speaker.stop()
        status = ""
    }

    // MARK: - Talking

    func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    /// Microphone first, then speech recognition (only needed for live transcription).
    private func requestVoicePermissions() async -> (microphone: Bool, speech: Bool) {
        guard await recorder.requestPermission() else { return (false, false) }
        return (true, await SpeechTranscriber.requestPermission())
    }

    /// Waiting for permissions before the microphone starts: a second tap must not start it twice.
    /// True from the tap until the microphone is really on, so the button reacts at once.
    @Published private(set) var isStartingMic = false

    private func startRecording() {
        guard canSend, !isStartingMic else { return }
        speaker.stop() // never record while Agatha is speaking
        isStartingMic = true
        Task {
            defer { isStartingMic = false }
            let allowed = await requestVoicePermissions()
            guard allowed.microphone else {
                status = "Please allow the microphone in Settings to talk to me."
                return
            }
            guard canSend else { return } // something else started while we waited
            // Live transcription when possible; otherwise record and let Whisper write it down.
            guard (allowed.speech && !preferWhisper && startLive()) || startRecorder() else {
                status = "The microphone did not start. Please try again."
                return
            }
            isRecording = true
            if isCallMode {
                status = ""
                watchForSilence()
            } else {
                status = "I'm listening… tap again when you're done."
            }
        }
    }

    private func startLive() -> Bool {
        do {
            try live.start(
                onChange: { [weak self] words in self?.liveText = words },
                onEnd: { [weak self] in self?.liveEndedByItself() }
            )
        } catch {
            live.cancel()
            return false
        }
        isLive = true
        liveText = ""
        liveStarted = Date()
        return true
    }

    private func startRecorder() -> Bool {
        do {
            try recorder.start()
        } catch {
            return false
        }
        isLive = false
        liveText = nil
        return true
    }

    private var liveStarted = Date()

    /// Recognition stopped by itself while the user was still meant to be talking.
    private func liveEndedByItself() {
        guard isRecording, isLive else { return }
        if !live.text.isEmpty {
            stopRecording() // it heard something: send what it heard
        } else if Date().timeIntervalSince(liveStarted) < Listen.liveFailedEarly {
            // Broke down straight away (e.g. no speech model on this phone): carry on with Whisper.
            live.cancel()
            liveText = nil
            preferWhisper = true
            if startRecorder() {
                if isCallMode { watchForSilence() }
            } else {
                isRecording = false
                status = "The microphone did not start. Please try again."
            }
        } else {
            giveUp()
        }
    }

    /// In a call: stop by itself when the user has finished talking.
    /// Live: when no new words have come for a moment (robust against chatter in the room).
    /// Whisper: when the microphone has gone quiet.
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
                let level = self.isLive ? self.live.currentLevel() : self.recorder.currentLevel()
                // The very first meter readings can be -160 (no signal yet): don't learn from those.
                if level > -100 { quietest = min(quietest ?? level, level) }
                let noise = quietest ?? -60
                let speechLevel = min(max(Listen.minSpeechLevel, noise + Listen.aboveNoise), Listen.maxSpeechLevel)
                let loud = level > speechLevel
                if self.isLive {
                    if let lastWords = self.live.lastChange {
                        heardSpeech = true
                        let sinceWords = now.timeIntervalSince(lastWords)
                        if sinceWords >= Listen.quietWords && (!loud || sinceWords >= Listen.quietWordsMax) {
                            self.stopRecording()
                            return
                        }
                    }
                } else if loud {
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
                    self.giveUp()
                    return
                }
            }
        }
    }

    /// Nothing was said: stop listening and throw it away.
    private func giveUp() {
        silenceWatch?.cancel()
        if isLive { live.cancel() } else { recorder.cancel() }
        liveText = nil
        isRecording = false
        status = isCallMode ? yourTurnStatus : "I did not hear anything. Please try again."
    }

    private func stopRecording() {
        guard isRecording else { return }
        silenceWatch?.cancel()
        isRecording = false
        isBusy = true
        if isLive {
            // The words are already written down: no Whisper round trip.
            status = "Thinking…"
            Task {
                let text = await live.finish()
                isBusy = false
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    liveText = nil
                    status = isCallMode ? yourTurnStatus : "I did not hear anything. Please try again."
                    return
                }
                liveText = nil // the live bubble becomes the normal message in the same step
                await userSays(text: text, image: nil)
            }
            return
        }
        let file = recorder.stop()
        status = "Writing down what you said…"
        Task {
            do {
                let text = try await api.transcribe(audioFile: file)
                isBusy = false
                guard !text.isEmpty else {
                    status = isCallMode ? yourTurnStatus : "I did not hear anything. Please try again."
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
        plan = DemoPerson.plan
        profile = DemoPerson.profile
        UserDefaults.standard.removeObject(forKey: "onboarded")
        takenToday = [:]
        skills = []
        for paper in papers { try? FileManager.default.removeItem(at: paper.fileURL) }
        notes = []
        papers = []
        save()
        messages = []
        showWelcome = false
    }

    /// Demo Plan B: load Margaret's sample medication plan without scanning it.
    func loadDemoPlan() {
        plan = DemoPerson.samplePlan
        takenToday = [:]
        save()
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
                profile: profile,
                notes: notesForServer()
            ))
        } catch {
            isBusy = false
            status = ""
            messages.append(ChatMessage(role: .assistant, text: error.localizedDescription, isError: true))
            _ = await speak(error.localizedDescription)
            if isCallMode { status = yourTurnStatus }
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
        } else if reply.cards.contains(where: { $0.type.hasPrefix("confirm_") }) {
            // Saving needs a tap on Yes/No, so don't start listening over the card.
            status = "Please check the card and tap Yes or No."
        } else if finished && canSend {
            if handsFree {
                try? await Task.sleep(for: .milliseconds(300)) // let the speaker go quiet first
                if isCallMode && canSend && !isSpeaking { startRecording() }
            } else {
                // Noisy rooms: don't pick up other people. The user taps when they want to answer.
                status = yourTurnStatus
            }
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
    /// App error bubbles stay on screen only: Claude never said them.
    private func historyForServer() -> [APIClient.HistoryItem] {
        let sent = messages.filter { !$0.isError }
        let newestImage = sent.lastIndex(where: { $0.image != nil })
        return sent.enumerated().map { index, m in
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
            case "open_screen":
                switch action.screen {
                case "home": pendingTab = .talk
                case "pills": pendingTab = .pills
                case "scan": pendingTab = .scan
                case "notes": pendingTab = .notes
                case "sos": pendingTab = .sos
                default: continue
                }
            case "save_note":
                guard let text = action.text, !text.isEmpty else { continue }
                notes.append(SavedNote(date: Date(), title: action.title ?? "Note", text: text, kind: action.kind ?? "note"))
            case "save_document":
                keepLastPhoto(title: action.title ?? "A letter", summary: action.summary ?? "")
            case "save_profile":
                guard let newProfile = action.profile else { continue }
                profile = newProfile
                // Onboarding is done once a profile is saved, even if they skipped their name.
                UserDefaults.standard.set(true, forKey: "onboarded")
                if isCallMode { endCallAfterReply = true }
            default:
                continue
            }
        }
        save()
    }

    // MARK: - Notes and papers

    func deleteNote(_ note: SavedNote) {
        notes.removeAll { $0.id == note.id }
        save()
    }

    func deletePaper(_ paper: SavedPaper) {
        try? FileManager.default.removeItem(at: paper.fileURL)
        papers.removeAll { $0.id == paper.id }
        save()
    }

    /// Saves the newest photo the user sent as a JPEG in Documents and lists it under "My papers".
    private func keepLastPhoto(title: String, summary: String) {
        guard let photo = messages.last(where: { $0.role == .user && $0.image != nil })?.image else { return }
        let paper = SavedPaper(date: Date(), title: title, summary: summary, fileName: "paper-\(UUID().uuidString).jpg")
        do {
            try Self.resizedJPEG(photo, maxSide: 2400).write(to: paper.fileURL, options: .atomic)
            papers.append(paper)
        } catch {
            status = "I could not keep that photo. Please try again."
        }
    }

    /// The newest 10 notes, long texts trimmed, so Agatha knows what is already written down.
    private func notesForServer() -> [APIClient.NoteSummary] {
        notes.suffix(10).map { note in
            .init(date: note.date.formatted(date: .abbreviated, time: .omitted),
                  title: note.title,
                  text: note.text.count > 200 ? String(note.text.prefix(200)) + "…" : note.text,
                  kind: note.kind)
        }
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
        defaults.set(try? JSONEncoder().encode(notes), forKey: "notes")
        defaults.set(try? JSONEncoder().encode(papers), forKey: "papers")
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
        if let data = defaults.data(forKey: "notes"), let saved = try? JSONDecoder().decode([SavedNote].self, from: data) {
            notes = saved
        }
        if let data = defaults.data(forKey: "papers"), let saved = try? JSONDecoder().decode([SavedPaper].self, from: data) {
            papers = saved
        }
    }

    /// Shrinks a photo to max 1600 px and encodes it as a JPEG data URL.
    static func dataURL(for image: UIImage) -> String {
        "data:image/jpeg;base64,\(resizedJPEG(image, maxSide: 1600).base64EncodedString())"
    }

    /// Shrinks a photo so its longest side is at most `maxSide` pixels and encodes it as JPEG.
    static func resizedJPEG(_ image: UIImage, maxSide: CGFloat) -> Data {
        let longest = max(image.size.width, image.size.height)
        let scale = min(1, maxSide / max(longest, 1))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1 // real pixels, not 3x screen points
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.85) ?? Data()
    }
}
