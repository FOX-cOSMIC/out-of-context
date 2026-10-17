import AVFoundation

/// Records the user's voice to an .m4a file. The server turns it into text (Whisper).
final class VoiceRecorder {
    private var recorder: AVAudioRecorder?
    private let fileURL = FileManager.default.temporaryDirectory.appending(path: "speech.m4a")

    func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        let newRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
        newRecorder.isMeteringEnabled = true // lets the call notice when the user stops talking
        guard newRecorder.record() else {
            throw NSError(domain: "VoiceRecorder", code: 1)
        }
        recorder = newRecorder
    }

    /// How loud the microphone is right now, in decibels (-160 = silence, 0 = loudest).
    func currentLevel() -> Float {
        guard let recorder else { return -160 }
        recorder.updateMeters()
        return recorder.averagePower(forChannel: 0)
    }

    /// Stops and returns the recorded file.
    func stop() -> URL {
        recorder?.stop()
        recorder = nil
        return fileURL
    }

    /// Stops and throws the recording away (nothing was said).
    func cancel() {
        recorder?.stop()
        recorder?.deleteRecording()
        recorder = nil
    }
}

/// Reads answers aloud. Uses the voice made on the server (this Mac);
/// falls back to the phone's own voice if the server can't be reached.
/// `say` returns when speaking is over: true if it finished, false if it was stopped.
@MainActor
final class Speaker: NSObject, AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate {
    private var player: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()
    private var utterance: AVSpeechUtterance?
    private var continuation: CheckedContinuation<Bool, Never>?
    private var currentRequest: UUID?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// `rate` is words per minute for the server voice; nil = normal speed.
    func say(_ text: String, rate: Int?, using api: APIClient) async -> Bool {
        stop()
        let request = UUID()
        currentRequest = request
        let audio = try? await api.speak(text, rate: rate)
        // Someone called stop() (or started something else) while the audio was being made.
        guard currentRequest == request else { return false }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            if let audio, let newPlayer = try? AVAudioPlayer(data: audio) {
                try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker])
                newPlayer.delegate = self
                player = newPlayer
                if !newPlayer.play() { finish(true) }
            } else {
                let newUtterance = AVSpeechUtterance(string: text)
                newUtterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
                newUtterance.rate = rate == nil ? 0.45 : 0.4
                utterance = newUtterance
                synthesizer.speak(newUtterance)
            }
        }
    }

    func stop() {
        currentRequest = nil
        player?.stop()
        player = nil
        utterance = nil
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        finish(false)
    }

    private func finish(_ completed: Bool) {
        let waiting = continuation
        continuation = nil
        waiting?.resume(returning: completed)
    }

    // MARK: Playback finished (delegates). Ignore late calls from an older player or utterance.

    nonisolated func audioPlayerDidFinishPlaying(_ finished: AVAudioPlayer, successfully flag: Bool) {
        let id = ObjectIdentifier(finished)
        Task { @MainActor in
            guard let player = self.player, ObjectIdentifier(player) == id else { return }
            self.player = nil
            self.finish(true)
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ failed: AVAudioPlayer, error: Error?) {
        audioPlayerDidFinishPlaying(failed, successfully: false)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish finished: AVSpeechUtterance) {
        let id = ObjectIdentifier(finished)
        Task { @MainActor in
            guard let utterance = self.utterance, ObjectIdentifier(utterance) == id else { return }
            self.utterance = nil
            self.finish(true)
        }
    }
}
