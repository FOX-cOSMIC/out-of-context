@preconcurrency import AVFoundation
import Foundation

/// What the Talk screen needs from "write down what the user says, live".
/// Both the phone's own recogniser (LiveTranscriber) and the helper Mac's Whisper (MacTranscriber) do this.
@MainActor
protocol SpeechTranscribing: AnyObject {
    var text: String { get }
    var lastChange: Date? { get }
    func start(onChange: @escaping (String) -> Void, onEnd: @escaping () -> Void) throws
    func finish() async -> String
    func cancel()
    func currentLevel() -> Float
}

extension LiveTranscriber: SpeechTranscribing {}
extension MacTranscriber: SpeechTranscribing {}

/// Picks the Mac or the phone each time listening starts, following the Settings switch
/// "Understand my voice on the helper computer" (stored as "speechOnMac", on by default).
@MainActor
final class SpeechTranscriber: SpeechTranscribing {
    static var usesMac: Bool {
        UserDefaults.standard.object(forKey: "speechOnMac") as? Bool ?? true
    }

    /// The Mac needs no speech permission (only the microphone); the phone's recogniser does.
    static func requestPermission() async -> Bool {
        if usesMac { return true }
        return await LiveTranscriber.requestPermission()
    }

    private let mac = MacTranscriber()
    private let phone = LiveTranscriber()
    private var current: SpeechTranscribing?

    var text: String { current?.text ?? "" }
    var lastChange: Date? { current?.lastChange }

    func start(onChange: @escaping (String) -> Void, onEnd: @escaping () -> Void) throws {
        cancel()
        let chosen: SpeechTranscribing = Self.usesMac ? mac : phone
        current = chosen
        try chosen.start(onChange: onChange, onEnd: onEnd)
    }

    func finish() async -> String { await current?.finish() ?? "" }
    func cancel() { current?.cancel() }
    func currentLevel() -> Float { current?.currentLevel() ?? -160 }
}

/// Writes down what the user says with Whisper on the helper Mac (POST /api/transcribe).
/// The microphone audio is kept in memory as 16 kHz mono PCM. While the user talks, the whole
/// recording so far is sent again about every 1.5 s, so the words appear (and correct themselves) live.
@MainActor
final class MacTranscriber {
    struct Unavailable: Error {}

    /// The words so far (empty until the first answer from the Mac).
    private(set) var text = ""
    /// When the words last changed: the user is still talking while this keeps moving.
    private(set) var lastChange: Date?

    private static let sampleRate = 16_000
    private static let maxSeconds = 60
    private static let sendEvery: Duration = .milliseconds(1500)
    private static let minNewAudio = sampleRate / 2      // at least 0.5 s new audio before sending again
    private static let partialTimeout: TimeInterval = 8
    private static let finalTimeout: Duration = .seconds(8)

    private var engine: AVAudioEngine?
    private let meter = MacLevelMeter()
    private let audio = PCMStore(maxSamples: sampleRate * maxSeconds)
    /// Changes every session, so late answers from an older session are ignored.
    private var session = UUID()
    private var onChange: ((String) -> Void)?
    private var onEnd: (() -> Void)?
    private var ticker: Task<Void, Never>?
    private var inFlight = false
    /// How many samples the last request contained.
    private var sentSamples = 0
    /// Answers can come back out of order: only a newer request may replace the words.
    private var nextRequest = 0
    private var appliedRequest = -1
    private var anyAnswer = false

    /// Starts listening. `onChange` gets the words each time they change; `onEnd` is called if the
    /// helper Mac cannot be reached on the first try (the app can then fall back).
    func start(onChange: @escaping (String) -> Void, onEnd: @escaping () -> Void) throws {
        cancel()
        try AudioSessionSetup.activate()
        let newEngine = AVAudioEngine()
        let input = newEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        // No microphone (some Simulators): installing a tap would crash, so give up cleanly.
        guard format.sampleRate > 0, format.channelCount > 0,
              let target = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: Double(Self.sampleRate),
                                         channels: 1, interleaved: true),
              let converter = AVAudioConverter(from: format, to: target) else { throw Unavailable() }

        audio.reset()
        meter.reset()
        input.installTap(onBus: 0, bufferSize: 4096, format: format,
                         block: Self.makeTap(converter: converter, target: target, store: audio, meter: meter))
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
        lastChange = nil
        inFlight = false
        sentSamples = 0
        nextRequest = 0
        appliedRequest = -1
        anyAnswer = false
        self.onChange = onChange
        self.onEnd = onEnd
        engine = newEngine
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.sendEvery)
                guard let self, self.session == id, self.engine != nil else { return }
                self.sendPartialIfNeeded(session: id)
            }
        }
    }

    /// How loud the microphone is right now, in decibels (-160 = silence, 0 = loudest).
    func currentLevel() -> Float { meter.level }

    /// The user has finished: stop the microphone, send the whole recording once more, return the words.
    func finish() async -> String {
        guard engine != nil else { return text }
        let id = session
        stopAudio()
        let samples = audio.snapshot()
        guard samples.count >= Self.sampleRate / 4 else { // under 0.25 s: nothing worth sending
            let words = text
            cancel()
            return words
        }
        let number = takeRequestNumber()
        let wav = Self.wav(samples)
        let final: String? = await withTaskGroup(of: String?.self) { group in
            group.addTask { try? await Self.post(wav, timeout: 10) }
            group.addTask { try? await Task.sleep(for: Self.finalTimeout); return nil }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
        if id == session, let final { apply(final, request: number) }
        let words = text
        cancel()
        return words
    }

    /// Stops and throws the words away.
    func cancel() {
        session = UUID()
        ticker?.cancel()
        ticker = nil
        stopAudio()
        inFlight = false
        onChange = nil
        onEnd = nil
    }

    private func stopAudio() {
        guard let engine else { return }
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        self.engine = nil
    }

    private func takeRequestNumber() -> Int {
        defer { nextRequest += 1 }
        return nextRequest
    }

    private func sendPartialIfNeeded(session id: UUID) {
        guard !inFlight else { return }
        let samples = audio.snapshot()
        guard samples.count - sentSamples >= Self.minNewAudio else { return }
        inFlight = true
        sentSamples = samples.count
        let number = takeRequestNumber()
        let wav = Self.wav(samples)
        Task { [weak self] in
            let result: String?
            do { result = try await Self.post(wav, timeout: Self.partialTimeout) } catch { result = nil }
            guard let self, self.session == id else { return }
            self.inFlight = false
            if let result {
                self.anyAnswer = true
                self.apply(result, request: number)
            } else if !self.anyAnswer && self.text.isEmpty {
                // The helper Mac did not answer the first time: let the app fall back.
                let end = self.onEnd
                self.cancel()
                end?()
            }
        }
    }

    private func apply(_ words: String, request number: Int) {
        guard number > appliedRequest else { return }
        appliedRequest = number
        let trimmed = words.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != text else { return }
        text = trimmed
        lastChange = Date()
        onChange?(trimmed)
    }

    // MARK: - Network and WAV (no main-actor state)

    private nonisolated static func post(_ wav: Data, timeout: TimeInterval) async throws -> String {
        var request = URLRequest(url: APIClient.baseURL.appending(path: "api/transcribe"))
        request.httpMethod = "POST"
        request.setValue("audio/wav", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout
        let (data, response) = try await URLSession.shared.upload(for: request, from: wav)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw Unavailable() }
        struct Result: Decodable { let text: String }
        return try JSONDecoder().decode(Result.self, from: data).text
    }

    /// 16-bit mono PCM samples -> a WAV file (44-byte RIFF header + the samples, little-endian).
    nonisolated static func wav(_ samples: [Int16], sampleRate: Int = 16_000) -> Data {
        let dataBytes = samples.count * 2
        var out = Data(capacity: 44 + dataBytes)
        func u32(_ v: Int) { var x = UInt32(v).littleEndian; withUnsafeBytes(of: &x) { out.append(contentsOf: $0) } }
        func u16(_ v: Int) { var x = UInt16(v).littleEndian; withUnsafeBytes(of: &x) { out.append(contentsOf: $0) } }
        out.append(contentsOf: Array("RIFF".utf8)); u32(36 + dataBytes)
        out.append(contentsOf: Array("WAVE".utf8))
        out.append(contentsOf: Array("fmt ".utf8)); u32(16)
        u16(1)                  // PCM
        u16(1)                  // mono
        u32(sampleRate)
        u32(sampleRate * 2)     // bytes per second
        u16(2)                  // bytes per frame
        u16(16)                 // bits per sample
        out.append(contentsOf: Array("data".utf8)); u32(dataBytes)
        samples.withUnsafeBytes { out.append(contentsOf: $0) }
        return out // iPhone CPUs are little-endian, so the samples are already in WAV byte order
    }

    // Runs on the audio thread, so it is built outside the main actor.
    private nonisolated static func makeTap(converter: AVAudioConverter, target: AVAudioFormat,
                                            store: PCMStore, meter: MacLevelMeter) -> AVAudioNodeTapBlock {
        { buffer, _ in
            meter.measure(buffer)
            guard !store.isFull else { return }
            let ratio = target.sampleRate / buffer.format.sampleRate
            let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 32
            guard let output = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: capacity) else { return }
            var given = false
            var error: NSError?
            let status = converter.convert(to: output, error: &error) { _, inputStatus in
                if given {
                    inputStatus.pointee = .noDataNow
                    return nil
                }
                given = true
                inputStatus.pointee = .haveData
                return buffer
            }
            guard status != .error, let samples = output.int16ChannelData?[0], output.frameLength > 0 else { return }
            store.append(UnsafeBufferPointer(start: samples, count: Int(output.frameLength)))
        }
    }
}

/// The recording so far (16 kHz mono Int16), written on the audio thread and read on the main thread.
private final class PCMStore: @unchecked Sendable {
    private let lock = NSLock()
    private var samples: [Int16] = []
    private let maxSamples: Int

    init(maxSamples: Int) { self.maxSamples = maxSamples }

    var isFull: Bool {
        lock.lock(); defer { lock.unlock() }
        return samples.count >= maxSamples
    }

    func reset() {
        lock.lock(); samples.removeAll(keepingCapacity: true); lock.unlock()
    }

    func append(_ new: UnsafeBufferPointer<Int16>) {
        lock.lock(); defer { lock.unlock() }
        let room = maxSamples - samples.count
        guard room > 0 else { return }
        samples.append(contentsOf: new.prefix(room))
    }

    func snapshot() -> [Int16] {
        lock.lock(); defer { lock.unlock() }
        return samples
    }
}

/// The microphone level, written on the audio thread and read on the main thread.
private final class MacLevelMeter: @unchecked Sendable {
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
