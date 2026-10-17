import AVFoundation
import AudioToolbox
import Combine
import SwiftUI
import UserNotifications

/// One medication-reminder "phone call" from Agatha (simulated: no real phone call is made).
struct CallInfo: Identifiable, Equatable {
    enum State: Equatable { case ringing, connected, callingFamily }

    let id = UUID()
    var slot: Slot
    /// Names of the medicines due in this slot, e.g. ["Metformin", "Simvastatin"].
    var medicines: [String]
    /// 1, 2 or 3.
    var attempt: Int
    /// "18:00": when the pills are due.
    var dueTime: String
    var state: State = .ringing
    /// Started from Settings / -testCall: retries 30 s apart, family told after 90 s.
    var isTest = false
    /// Set when the call is accepted or the notification tapped (for the "on call" timer).
    var connectedAt: Date?
    /// The user confirmed they have taken this slot's medicines (confirmIntake).
    var isConfirmed = false
    /// Doses were still open when the call came (ticking them all off during the call then confirms it).
    var hadOpenDoses = false

    /// "Evening pills"
    var slotTitle: String { "\(slot.label) pills" }
    /// "Evening pills · Metformin, Simvastatin"
    var detail: String {
        medicines.isEmpty ? slotTitle : "\(slotTitle) · \(medicines.joined(separator: ", "))"
    }
    /// "Second try" / "Last try"; nil on the first attempt.
    var attemptLabel: String? {
        switch attempt {
        case 2: "Second try"
        case 3...: "Last try"
        default: nil
        }
    }
}

/// Agatha's pill reminders for today, as simulated phone calls.
///
/// Each slot has a fixed time (Settings → Medication times; defaults 09:00, 13:00, 18:00, 21:00).
/// At that time Agatha rings (in the app) or a notification with her ringtone appears (in the background).
/// Unconfirmed: she tries again after 10 and 20 minutes; still unconfirmed 30 minutes after the time,
/// the family helper "is told" (simulated) and it goes into `missedLog`. Test calls use 30 s / 60 s / 90 s.
/// Accepting the call or tapping the notification opens the in-call screen, where Agatha talks hands-free;
/// confirming (slider, or by voice via confirmIntake) ends the call and the reminders for that slot today.
@MainActor
final class CallScheduler: NSObject, ObservableObject {
    static let shared = CallScheduler()

    /// The full-screen call: ringing, connected (in-call screen) or "couldn't reach you". nil = none.
    @Published private(set) var activeCall: CallInfo?
    /// The call the user picked up (accept or notification tap), while it lasts; nil otherwise.
    @Published private(set) var connectedCall: CallInfo?
    /// Called when a call is picked up: start Agatha's side of the conversation (she speaks first,
    /// hands-free). Set by the app, e.g. `{ model.startMedicationCall(slot: $0.slot, ...) }`.
    var onAccepted: ((CallInfo) -> Void)?
    /// Called after the user ticks or unticks a medicine on the call screen: (slot, ticked names,
    /// names still to take). Lets Agatha hear what was ticked.
    var onPillsTicked: ((Slot, [String], [String]) -> Void)?
    /// Slots confirmed today (kept in UserDefaults, reset each day).
    @Published private(set) var confirmedSlots: Set<Slot> = []

    /// Called once per slot when it is confirmed (slider or voice), with that slot's medicine names.
    /// The slider already ticks the medicines off in ChatModel; use this for anything extra.
    var onConfirm: ((Slot, [String]) -> Void)?

    /// When the family helper "was told" (newest last). Kept in UserDefaults.
    private(set) var missedLog: [Date] {
        get { (UserDefaults.standard.array(forKey: Keys.missedLog) as? [Date]) ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: Keys.missedLog) }
    }

    private enum Keys {
        static let missedLog = "callMissedLog"
        static let handled = "callHandledAttempts"
        static let confirmed = "callConfirmedSlots"
    }

    private enum Timing {
        static let retry: TimeInterval = 10 * 60
        static let testRetry: TimeInterval = 30
        static let ringFor: TimeInterval = 30
        static let testRingFor: TimeInterval = 25 // ends before the next test try
        static let checkEvery: TimeInterval = 5
        /// Opening the app a little after a reminder was due still rings it.
        static let lateGrace: TimeInterval = 9 * 60
        static let hangUpAfterConfirm: TimeInterval = 2.5
        static let attempts = 3
        /// Event number for "tell the family" (after the three tries).
        static let escalation = 4
    }

    /// A planned try (1...3) or the escalation (4).
    private struct Planned {
        var slot: Slot
        var attempt: Int
        var date: Date
        var isTest: Bool
    }

    private weak var model: ChatModel?
    private var planned: [Planned] = []
    /// Slots running a test call: rebuild() leaves them alone.
    private var overridden: Set<Slot> = []
    private var checkTimer: Timer?
    private var ringTimer: Timer?
    private var timeoutTimer: Timer?
    private var ringtone: AVAudioPlayer?
    private var watchers: Set<AnyCancellable> = []
    private var day = CallScheduler.dayString(Date())
    /// A notification was tapped before the model was attached.
    private var pendingTap: (slot: Slot, attempt: Int, isTest: Bool)?

    // MARK: - Setup

    /// Called once from the app with the shared model. Starts the timer and plans today's reminders.
    func attach(model: ChatModel) {
        guard self.model == nil else { return }
        self.model = model
        loadConfirmed()

        // The plan changed: plan again. Pills ticked off: drop what is left for that slot.
        model.$plan
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.rebuild() }
            .store(in: &watchers)
        model.$takenToday
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.cancelTakenSlots() }
            .store(in: &watchers)

        rebuild()
        checkTimer = Timer.scheduledTimer(withTimeInterval: Timing.checkEvery, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }

        if let tap = pendingTap {
            pendingTap = nil
            openFromNotification(slot: tap.slot, attempt: tap.attempt, isTest: tap.isTest)
        }
        // Demo hook: launch with the argument -testCall to ring 3 seconds after start.
        if ProcessInfo.processInfo.arguments.contains("-testFamilyCall") {
            // Demo hook: show "Calling Anna" right away.
            tellFamily(nextDueSlot() ?? .evening, isTest: true)
        } else if ProcessInfo.processInfo.arguments.contains("-testCall") {
            startTestCall(after: 3)
        } else {
            askForNotifications()
        }
    }

    /// Ask once (iOS shows the question only the first time), never on top of a ringing call.
    private func askForNotifications() {
        guard activeCall == nil else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - Public API

    /// Rings in `seconds` for the next slot with pills still to take (evening if none), in test mode:
    /// tries again after 30 s and 60 s, tells the family after 90 s unless confirmed.
    func startTestCall(after seconds: Double = 10) {
        let slot = nextDueSlot() ?? .evening
        overridden.insert(slot)
        planned.removeAll { $0.slot == slot }
        let start = Date().addingTimeInterval(max(seconds, 1))
        for event in 1...Timing.escalation {
            let date = start.addingTimeInterval(Double(event - 1) * Timing.testRetry)
            planned.append(Planned(slot: slot, attempt: event, date: date, isTest: true))
        }
        unmarkHandled(slot)
        confirmedSlots.remove(slot)
        saveConfirmed()
        syncNotifications()
    }

    /// Settings changed a medication time: plan today again.
    func reschedule() {
        rebuild()
    }

    /// Accept: the in-call screen shows and Agatha speaks first (onAccepted).
    func accept() {
        guard let call = activeCall, call.state == .ringing else { return }
        stopRinging()
        markHandled(call.slot, call.attempt)
        connect(call)
    }

    /// Declining counts like not answering: the next try comes at its time.
    func decline() {
        guard let call = activeCall, call.state == .ringing else { return }
        stopRinging()
        markHandled(call.slot, call.attempt)
        activeCall = nil
        askForNotifications()
    }

    /// End call, or OK on the "couldn't reach you" screen. Hung up without confirming: Agatha calls
    /// back (next try at least 10 min / test 30 s from now), and the family is told 30 min after the time.
    func endCall() {
        stopRinging()
        if let call = connectedCall, !call.isConfirmed { pushBackTries(call) }
        if connectedCall != nil, let model, model.isCallMode { model.endCall() }
        activeCall = nil
        connectedCall = nil
        askForNotifications()
    }

    /// After an unconfirmed call: the remaining tries come no sooner than one spacing from now
    /// (but never after the family is told).
    private func pushBackTries(_ call: CallInfo) {
        let spacing = call.isTest ? Timing.testRetry : Timing.retry
        let escalation = planned.first { $0.slot == call.slot && $0.attempt == Timing.escalation }?.date
        var step = 1.0
        for i in planned.indices where planned[i].slot == call.slot && planned[i].attempt < Timing.escalation {
            planned[i].date = max(planned[i].date, Date().addingTimeInterval(step * spacing))
            step += 1
        }
        if let escalation {
            planned.removeAll { $0.slot == call.slot && $0.attempt < Timing.escalation && $0.date >= escalation }
        }
        syncNotifications()
    }

    /// The user has taken this slot's medicines (slider, or Agatha heard it). Safe to call again.
    /// Cancels the slot's remaining tries; a connected call for it ends after a short pause.
    func confirmIntake(for slot: Slot) {
        let isNew = !confirmedSlots.contains(slot)
        confirmedSlots.insert(slot)
        saveConfirmed()
        planned.removeAll { $0.slot == slot }
        syncNotifications()
        if isNew { onConfirm?(slot, medicines(slot).map(\.name)) }

        if let call = activeCall, call.slot == slot, call.state == .ringing {
            stopRinging()
            activeCall = nil
        }
        guard var call = connectedCall, call.slot == slot, !call.isConfirmed else { return }
        call.isConfirmed = true
        connectedCall = call
        activeCall = call
        let id = call.id
        DispatchQueue.main.asyncAfter(deadline: .now() + Timing.hangUpAfterConfirm) { [weak self] in
            guard let self, self.connectedCall?.id == id else { return }
            self.endCall()
        }
    }

    /// A checkbox on the call screen: tick (or untick) one medicine; all ticked = confirmed.
    func toggle(_ med: Medication, slot: Slot) {
        guard let model else { return }
        model.toggleTaken(med, slot: slot)
        let meds = medicines(slot)
        let ticked = meds.filter { model.isTaken($0, slot: slot) }.map(\.name)
        let remaining = meds.filter { !model.isTaken($0, slot: slot) }.map(\.name)
        onPillsTicked?(slot, ticked, remaining)
        if remaining.isEmpty, !meds.isEmpty { confirmIntake(for: slot) }
    }

    /// "Confirm all" on the call screen: tick off every medicine of the slot, then confirm.
    func confirmAll(slot: Slot) {
        if let model {
            for med in medicines(slot) where !model.isTaken(med, slot: slot) {
                model.toggleTaken(med, slot: slot)
            }
        }
        confirmIntake(for: slot)
    }

    /// The medicines due in a slot.
    func medicines(_ slot: Slot) -> [Medication] {
        guard let model else { return [] }
        return model.plan.medications.filter {
            let dose = $0.times.dose(for: slot).trimmingCharacters(in: .whitespaces)
            return !dose.isEmpty && dose != "0" && dose != "-"
        }
    }

    // MARK: - Planning

    /// Today's tries and escalation from the plan and the medication times.
    private func rebuild() {
        guard model != nil else { return }
        let now = Date()
        planned.removeAll { !overridden.contains($0.slot) }
        for slot in Slot.allCases where !overridden.contains(slot) && !confirmedSlots.contains(slot) {
            guard !untakenMedicines(slot).isEmpty else { continue }
            let first = MedicationTimes.date(for: slot, on: now)
            for event in 1...Timing.escalation {
                let date = first.addingTimeInterval(Double(event - 1) * Timing.retry)
                guard date > now.addingTimeInterval(-Timing.lateGrace), !isHandled(slot, event) else { continue }
                planned.append(Planned(slot: slot, attempt: event, date: date, isTest: false))
            }
        }
        syncNotifications()
    }

    /// Every 5 s: a new day plans again; a due try rings unless the user is busy or already on a call.
    private func tick() {
        let today = Self.dayString(Date())
        if today != day {
            day = today
            overridden.removeAll()
            UserDefaults.standard.removeObject(forKey: Keys.handled)
            confirmedSlots = []
            saveConfirmed()
            rebuild()
        }
        guard activeCall == nil, connectedCall == nil,
              let model, !model.isRecording, !model.isBusy else { return }
        let now = Date()
        let due = planned.filter { $0.date <= now }
        guard let latest = due.max(by: { $0.attempt < $1.attempt }) else { return }
        for item in due { markHandled(item.slot, item.attempt) }
        planned.removeAll { item in due.contains { $0.slot == item.slot && $0.attempt == item.attempt } }
        if confirmedSlots.contains(latest.slot) { return }
        if untakenMedicines(latest.slot).isEmpty && !latest.isTest { return }

        if latest.attempt == Timing.escalation {
            tellFamily(latest.slot, isTest: latest.isTest)
        } else {
            ring(makeCall(latest.slot, attempt: latest.attempt, isTest: latest.isTest))
        }
    }

    /// 30 minutes without a confirmation: Agatha "calls" the family helper (simulated, no real call).
    private func tellFamily(_ slot: Slot, isTest: Bool) {
        planned.removeAll { $0.slot == slot }
        syncNotifications()
        missedLog.append(Date())
        activeCall = makeCall(slot, attempt: Timing.attempts, isTest: isTest, state: .callingFamily)
    }

    private func makeCall(_ slot: Slot, attempt: Int, isTest: Bool, state: CallInfo.State = .ringing) -> CallInfo {
        let open = untakenMedicines(slot)
        let names = open.isEmpty ? medicines(slot).map(\.name) : open // test call after the pills were taken
        return CallInfo(slot: slot, medicines: names.map(Self.shortName), attempt: attempt,
                        dueTime: MedicationTimes.string(for: slot), state: state, isTest: isTest,
                        hadOpenDoses: !open.isEmpty)
    }

    private func connect(_ call: CallInfo) {
        var call = call
        call.state = .connected
        call.connectedAt = Date()
        activeCall = call
        connectedCall = call
        onAccepted?(call)
    }

    /// Pills ticked off (Pills tab, or Agatha's mark_taken): drop that slot's remaining tries;
    /// all of a connected call's pills ticked off counts as confirming it.
    private func cancelTakenSlots() {
        let before = planned.count
        planned.removeAll { !$0.isTest && untakenMedicines($0.slot).isEmpty }
        if planned.count != before { syncNotifications() }
        if let call = connectedCall, !call.isConfirmed, call.hadOpenDoses,
           untakenMedicines(call.slot).isEmpty {
            confirmIntake(for: call.slot)
        }
    }

    // MARK: - Ringing

    private func ring(_ call: CallInfo) {
        activeCall = call
        stopRinging()
        #if DEBUG
        // Verification hook: -testCall -testCallAccept picks up by itself after 3 s of ringing.
        if ProcessInfo.processInfo.arguments.contains("-testCallAccept") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in self?.accept() }
        }
        #endif
        startRingtone()
        vibrate()
        ringTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            Task { @MainActor in CallScheduler.shared.vibrate() }
        }
        let ringFor = call.isTest ? Timing.testRingFor : Timing.ringFor
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: ringFor, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.decline() } // not answered = declined
        }
    }

    /// Agatha's own ringtone (Sounds/agatha-ring.caf: a soft two-note chime, 2 s, looped).
    private func startRingtone() {
        guard let url = Bundle.main.url(forResource: "agatha-ring", withExtension: "caf") else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            // .playback while ringing (a .playAndRecord session here made SwiftUI fire the Accept
            // button by itself in the Simulator); the app's own session comes back in stopRinging().
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 1.0
            player.play()
            ringtone = player
        } catch {
            AudioServicesPlayAlertSound(SystemSoundID(1005)) // fallback: a system sound
        }
    }

    /// Back to the app's session so Agatha's voice and the microphone work in the call.
    private func restoreAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default,
                                                         options: [.defaultToSpeaker, .allowBluetoothHFP])
    }

    /// The ring-back tone while Agatha "calls" the family helper (Sounds/outgoing-ring.caf, looped).
    func startOutgoingTone() {
        guard let url = Bundle.main.url(forResource: "outgoing-ring", withExtension: "caf") else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        ringtone?.stop()
        ringtone = try? AVAudioPlayer(contentsOf: url)
        ringtone?.numberOfLoops = -1
        ringtone?.play()
    }

    func stopOutgoingTone() {
        stopRinging()
    }

    private func vibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    private func stopRinging() {
        if ringtone != nil {
            ringtone?.stop()
            ringtone = nil
            restoreAudioSession()
        }
        ringTimer?.invalidate()
        ringTimer = nil
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }

    /// Tapping a reminder notification: straight into the call (no ringing first).
    private func openFromNotification(slot: Slot, attempt: Int, isTest: Bool) {
        guard model != nil else {
            pendingTap = (slot, attempt, isTest)
            return
        }
        stopRinging()
        if attempt == Timing.escalation {
            if activeCall == nil, !confirmedSlots.contains(slot) {
                activeCall = makeCall(slot, attempt: Timing.attempts, isTest: isTest, state: .callingFamily)
            }
            return
        }
        for a in 1...attempt { markHandled(slot, a) }
        planned.removeAll { $0.slot == slot && $0.attempt <= attempt }
        if confirmedSlots.contains(slot) || connectedCall != nil { return }
        connect(makeCall(slot, attempt: attempt, isTest: isTest))
    }

    // MARK: - Notifications (the reminder while the app is in the background)

    private func syncNotifications() {
        let center = UNUserNotificationCenter.current()
        let ids = Slot.allCases.flatMap { slot in (1...Timing.escalation).map { Self.notificationID(slot, $0) } }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        let now = Date()
        for item in planned where item.date > now.addingTimeInterval(1) {
            let content = UNMutableNotificationContent()
            if item.attempt == Timing.escalation {
                content.title = "Agatha couldn't reach you"
                content.body = "\(helperLine) (Demo: no real call is made.)"
                content.sound = .default
            } else {
                content.title = "Agatha: time for your \(item.slot.rawValue) pills"
                content.body = item.attempt == 1
                    ? "Tap to confirm you've taken them"
                    : "Reminder \(item.attempt) of 3 · Tap to confirm you've taken them"
                // Sounds/agatha-ring-long.caf (24 s; iOS plays at most 30 s of a notification sound).
                content.sound = UNNotificationSound(named: UNNotificationSoundName("agatha-ring-long.caf"))
            }
            content.interruptionLevel = .timeSensitive
            content.userInfo = ["slot": item.slot.rawValue, "attempt": item.attempt, "test": item.isTest]
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: item.date.timeIntervalSince(now), repeats: false)
            center.add(UNNotificationRequest(identifier: Self.notificationID(item.slot, item.attempt),
                                             content: content, trigger: trigger))
        }
    }

    /// "Anna (your daughter) has been told." from the profile.
    var helperLine: String {
        let name = model?.profile.helper_name ?? ""
        guard !name.isEmpty else { return "Your family helper has been told." }
        let relation = model?.profile.helper_relation ?? ""
        return relation.isEmpty ? "\(name) has been told." : "\(name) (your \(relation)) has been told."
    }

    private static func notificationID(_ slot: Slot, _ attempt: Int) -> String {
        "agatha.call.\(slot.rawValue).\(attempt)"
    }

    // MARK: - Medicines

    private func untakenMedicines(_ slot: Slot) -> [String] {
        guard let model else { return [] }
        return medicines(slot).filter { !model.isTaken($0, slot: slot) }.map(\.name)
    }

    /// The first slot from now on with pills still to take, else any slot with pills left.
    private func nextDueSlot() -> Slot? {
        let now = Date()
        let open = Slot.allCases.filter { !untakenMedicines($0).isEmpty }
        return open.first { MedicationTimes.date(for: $0, on: now) >= now.addingTimeInterval(-Timing.lateGrace) }
            ?? open.last
    }

    /// "Acetylsalicylic acid (ASS 100)" -> "Acetylsalicylic acid" (keeps the call screen short).
    static func shortName(_ name: String) -> String {
        guard let paren = name.firstIndex(of: "(") else { return name }
        let short = name[..<paren].trimmingCharacters(in: .whitespaces)
        return short.isEmpty ? name : short
    }

    // MARK: - Saved state (so a relaunch does not ring the same try again)

    private func handledKey(_ slot: Slot, _ attempt: Int) -> String { "\(day).\(slot.rawValue).\(attempt)" }

    private func isHandled(_ slot: Slot, _ attempt: Int) -> Bool {
        (UserDefaults.standard.stringArray(forKey: Keys.handled) ?? []).contains(handledKey(slot, attempt))
    }

    private func markHandled(_ slot: Slot, _ attempt: Int) {
        var list = UserDefaults.standard.stringArray(forKey: Keys.handled) ?? []
        list.removeAll { !$0.hasPrefix(day) }
        list.append(handledKey(slot, attempt))
        UserDefaults.standard.set(list, forKey: Keys.handled)
    }

    private func unmarkHandled(_ slot: Slot) {
        var list = UserDefaults.standard.stringArray(forKey: Keys.handled) ?? []
        list.removeAll { $0.hasPrefix("\(day).\(slot.rawValue).") }
        UserDefaults.standard.set(list, forKey: Keys.handled)
    }

    private func loadConfirmed() {
        let list = UserDefaults.standard.stringArray(forKey: Keys.confirmed) ?? []
        confirmedSlots = Set(list.compactMap { entry in
            entry.hasPrefix("\(day).") ? Slot(rawValue: String(entry.dropFirst(day.count + 1))) : nil
        })
    }

    private func saveConfirmed() {
        UserDefaults.standard.set(confirmedSlots.map { "\(day).\($0.rawValue)" }, forKey: Keys.confirmed)
    }

    private static func dayString(_ date: Date) -> String { date.formatted(.iso8601.year().month().day()) }
}

// MARK: - Fixed medication times (Settings → Medication times)

/// One fixed time per slot, saved in UserDefaults as "HH:mm" under schedule.morning etc.
enum MedicationTimes {
    static func key(_ slot: Slot) -> String { "schedule.\(slot.rawValue)" }

    static func defaultString(_ slot: Slot) -> String {
        switch slot {
        case .morning: "09:00"
        case .midday: "13:00"
        case .evening: "18:00"
        case .night: "21:00"
        }
    }

    /// "18:00"
    static func string(for slot: Slot) -> String {
        let saved = UserDefaults.standard.string(forKey: key(slot)) ?? ""
        return parse(saved) == nil ? defaultString(slot) : saved
    }

    static func parse(_ text: String) -> (hour: Int, minute: Int)? {
        let parts = text.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2, (0...23).contains(parts[0]), (0...59).contains(parts[1]) else { return nil }
        return (parts[0], parts[1])
    }

    /// Today's (or `date`'s) time for the slot.
    static func date(for slot: Slot, on date: Date) -> Date {
        let (hour, minute) = parse(string(for: slot)) ?? (18, 0)
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }

    static func set(_ date: Date, for slot: Slot) {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        UserDefaults.standard.set(String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0), forKey: key(slot))
    }
}

/// Four time pickers for Settings (put it inside the Settings Form/List).
struct MedicationTimesSection: View {
    @EnvironmentObject private var scheduler: CallScheduler
    @State private var times: [Slot: Date] = [:]

    var body: some View {
        Section {
            ForEach(Slot.allCases, id: \.self) { slot in
                DatePicker(selection: binding(slot), displayedComponents: .hourAndMinute) {
                    Label(slot.label, systemImage: icon(slot))
                        .font(Theme.Typeface.body(21, weight: .bold))
                }
                .font(Theme.Typeface.body(21))
                .padding(.vertical, 4)
            }
        } header: {
            Text("Medication times").font(Theme.Typeface.body(18, weight: .bold))
        } footer: {
            Text("Agatha calls you at these times to remind you of your pills.")
                .font(Theme.Typeface.body(17))
        }
        .onAppear {
            for slot in Slot.allCases { times[slot] = MedicationTimes.date(for: slot, on: Date()) }
        }
    }

    private func binding(_ slot: Slot) -> Binding<Date> {
        Binding(
            get: { times[slot] ?? MedicationTimes.date(for: slot, on: Date()) },
            set: { newValue in
                times[slot] = newValue
                MedicationTimes.set(newValue, for: slot)
                scheduler.reschedule()
            })
    }

    private func icon(_ slot: Slot) -> String {
        switch slot {
        case .morning: "sunrise.fill"
        case .midday: "sun.max.fill"
        case .evening: "sunset.fill"
        case .night: "moon.stars.fill"
        }
    }
}

// MARK: - Tapping a reminder notification opens the call

extension CallScheduler: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        let info = response.notification.request.content.userInfo
        let slot = (info["slot"] as? String).flatMap(Slot.init(rawValue:))
        let attempt = info["attempt"] as? Int ?? 1
        let isTest = info["test"] as? Bool ?? false
        Task { @MainActor in
            if let slot { CallScheduler.shared.openFromNotification(slot: slot, attempt: attempt, isTest: isTest) }
            completionHandler()
        }
    }

    /// In the app the call screen rings by itself, so no banner.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let isCall = notification.request.identifier.hasPrefix("agatha.call.")
        Task { @MainActor in
            if isCall { CallScheduler.shared.tick() }
            completionHandler(isCall ? [] : [.banner, .sound])
        }
    }
}
