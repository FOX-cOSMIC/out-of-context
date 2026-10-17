import AVFoundation
import Speech

/// Writes down what the user says while they speak (Apple's Speech framework, on the phone when it can).
/// The words arrive as they are recognised, so the app can show them live.
/// If this is not available, the app falls back to VoiceRecorder + Whisper on the server.
@MainActor
final class LiveTranscriber {
    struct Unavailable: Error {}

    /// The words so far (empty until the first word is recognised).
    private(set) var text = ""
    /// When the words last changed: the user is still talking while this keeps moving.
    private(set) var lastChange: Date?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-GB"))
    private var engine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let meter = LevelMeter()
    /// The microphone tap feeds whatever request is current, so recognition can restart mid-speech.
    private let feed = RequestFeed()
    /// Words from earlier sections: Apple starts a fresh section after a pause and only reports the new words.
    private var committed = ""
    /// The words of the current section.
    private var current = ""
    private var gotFinal = false
    /// Changes every session, so late results from an older session are ignored.
    private var session = UUID()
    private var onChange: ((String) -> Void)?
    private var onEnd: (() -> Void)?

    /// Asks once for speech recognition. True if the user allowed it.
    static func requestPermission() async -> Bool {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized: return true
        case .denied, .restricted: return false
        default:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }

    /// Starts listening. `onChange` gets the words each time they change; `onEnd` is called if
    /// recognition stops by itself (an error, or the recogniser decided the speech is over).
    /// Throws if live transcription cannot run here: then use the Whisper path instead.
    func start(onChange: @escaping (String) -> Void, onEnd: @escaping () -> Void) throws {
        cancel()
        guard SFSpeechRecognizer.authorizationStatus() == .authorized,
              let recognizer, recognizer.isAvailable else { throw Unavailable() }

        try AudioSessionSetup.activate()
        let newEngine = AVAudioEngine()
        let input = newEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        // No microphone (some Simulators): installing a tap would crash, so give up cleanly.
        guard format.sampleRate > 0, format.channelCount > 0 else { throw Unavailable() }

        let newRequest = Self.makeRequest(recognizer)
        feed.set(newRequest)

        meter.reset()
        input.installTap(onBus: 0, bufferSize: 1024, format: format, block: Self.makeTap(feed: feed, meter: meter))
        newEngine.prepare()
        do {
            try newEngine.start()
        } catch {
            input.removeTap(onBus: 0)
            throw error
        }

        let id = UUID()
        session = id
        text = ""
        committed = ""
        current = ""
        lastChange = nil
        gotFinal = false
        self.onChange = onChange
        self.onEnd = onEnd
        engine = newEngine
        startTask(newRequest, session: id)
    }

    private static func makeRequest(_ recognizer: SFSpeechRecognizer) -> SFSpeechAudioBufferRecognitionRequest {
        let newRequest = SFSpeechAudioBufferRecognitionRequest()
        newRequest.shouldReportPartialResults = true
        newRequest.taskHint = .dictation
        newRequest.addsPunctuation = true
        // Stay on the phone when it can; otherwise Apple's server recognises it.
        if recognizer.supportsOnDeviceRecognition { newRequest.requiresOnDeviceRecognition = true }
        return newRequest
    }

    private func startTask(_ newRequest: SFSpeechAudioBufferRecognitionRequest, session id: UUID) {
        guard let recognizer else { return }
        request = newRequest
        task = recognizer.recognitionTask(with: newRequest, resultHandler: Self.makeResultHandler { [weak self] words, isFinal, failed in
            self?.handle(words: words, isFinal: isFinal, failed: failed, session: id)
        })
    }

    /// Apple ended recognition (after a pause) while the user is still talking: keep the words, listen on.
    private func continueListening(session id: UUID) {
        guard let recognizer, engine != nil else { return }
        commitCurrent()
        task = nil
        let next = Self.makeRequest(recognizer)
        feed.set(next)
        startTask(next, session: id)
    }

    private func commitCurrent() {
        guard !current.isEmpty else { return }
        committed = committed.isEmpty ? current : committed + " " + current
        current = ""
    }

    /// How loud the microphone is right now, in decibels (-160 = silence, 0 = loudest).
    func currentLevel() -> Float { meter.level }

    /// The user has finished: stop the microphone, wait a moment for the final words, return them.
    func finish() async -> String {
        guard request != nil else { return text }
        stopAudio()
        request?.endAudio()
        // The last words usually arrive within a few hundred milliseconds.
        for _ in 0..<20 where !gotFinal { // up to 2 s, in case recognition runs on a slow network
            try? await Task.sleep(for: .milliseconds(100))
        }
        let words = text
        cancel()
        return words
    }

    /// Stops and throws the words away.
    func cancel() {
        session = UUID()
        stopAudio()
        task?.cancel()
        task = nil
        request = nil
        feed.set(nil)
        onChange = nil
        onEnd = nil
    }

    private func stopAudio() {
        guard let engine else { return }
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        self.engine = nil
    }

    private func handle(words: String?, isFinal: Bool, failed: Bool, session id: UUID) {
        guard id == session else { return }
        if let words, !words.isEmpty, words != current {
            // A fresh section after a pause: the new words don't continue the old ones, so keep the old.
            let continues = current.isEmpty || words.lowercased().hasPrefix(String(current.lowercased().prefix(8)))
            if !continues && words.count < current.count { commitCurrent() }
            current = words
            let all = committed.isEmpty ? current : committed + " " + current
            if all != text {
                text = all
                lastChange = Date()
                onChange?(all)
            }
        }
        guard isFinal || failed else { return }
        if engine != nil {
            // The user has not tapped yet. Words so far: carry on in a new section.
            // Nothing heard at all and it failed: tell the model (it may fall back to Whisper).
            if failed && text.isEmpty { gotFinal = true; onEnd?() } else { continueListening(session: id) }
        } else {
            commitCurrent()
            gotFinal = true
        }
    }

    // These run on audio / recognition threads, so they are built outside the main actor.

    private nonisolated static func makeTap(feed: RequestFeed, meter: LevelMeter) -> AVAudioNodeTapBlock {
        { buffer, _ in
            feed.append(buffer)
            meter.measure(buffer)
        }
    }

    private nonisolated static func makeResultHandler(
        _ deliver: @escaping @MainActor (String?, Bool, Bool) -> Void
    ) -> (SFSpeechRecognitionResult?, Error?) -> Void {
        { result, error in
            let words = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            let failed = error != nil
            Task { @MainActor in deliver(words, isFinal, failed) }
        }
    }
}

/// The microphone level, written on the audio thread and read on the main thread.
private final class LevelMeter: @unchecked Sendable {
    private let lock = NSLock()
    private var current: Float = -160

    var level: Float {
        lock.lock(); defer { lock.unlock() }
        return current
    }

    func reset() {
        lock.lock(); current = -160; lock.unlock()
    }

    func measure(_ buffer: AVAudioPCMBuffer) {
        guard let samples = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return }
        var sum: Float = 0
        for i in 0..<Int(buffer.frameLength) { sum += samples[i] * samples[i] }
        let rms = (sum / Float(buffer.frameLength)).squareRoot()
        let decibels = rms > 0 ? max(20 * log10(rms), -160) : -160
        lock.lock(); current = decibels; lock.unlock()
    }
}

/// The recognition request the microphone feeds; swapped when recognition restarts mid-speech.
private final class RequestFeed: @unchecked Sendable {
    private let lock = NSLock()
    private var request: SFSpeechAudioBufferRecognitionRequest?

    func set(_ newRequest: SFSpeechAudioBufferRecognitionRequest?) {
        lock.lock(); request = newRequest; lock.unlock()
    }

    func append(_ buffer: AVAudioPCMBuffer) {
        lock.lock(); let current = request; lock.unlock()
        current?.append(buffer)
    }
}
