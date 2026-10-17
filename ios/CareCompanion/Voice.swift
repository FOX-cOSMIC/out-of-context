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
        recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder?.record()
    }

    /// Stops and returns the recorded file.
    func stop() -> URL {
        recorder?.stop()
        recorder = nil
        return fileURL
    }
}

/// Reads answers aloud. Uses the voice made on the server (this Mac);
/// falls back to the phone's own voice if the server can't be reached.
@MainActor
final class Speaker: NSObject {
    private var player: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()

    func say(_ text: String, using api: APIClient) async {
        stop()
        do {
            let audio = try await api.speak(text)
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker])
            player = try AVAudioPlayer(data: audio)
            player?.play()
        } catch {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
            utterance.rate = 0.45
            synthesizer.speak(utterance)
        }
    }

    func stop() {
        player?.stop()
        synthesizer.stopSpeaking(at: .immediate)
    }
}
