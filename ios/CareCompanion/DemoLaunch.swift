import SwiftUI

// Demo-video launch arguments: record every scene without tapping.
//   xcrun simctl launch <sim> com.outofcontext.carecompanion <args>
//
//   -demoReset                  start clean as Margaret with her demo plan (like Settings → delete all data)
//   -demoTab <pills|scan|home|notes|sos>   open that tab after launch ("talk" = "home")
//   -demoSheet <history|calendar>          on Pills: open "My week & month" or "My calendar" (implies -demoTab pills)
//   -demoAsk "<text>"           after a short delay, send this text to Agatha as if typed
//   -demoAskDelay <seconds>     delay for -demoAsk and -demoScan (default 2.5)
//   -demoScan <path|sample-plan|sample-amlodipine|sample>
//                               after the delay, send this photo to Agatha. A path is absolute or relative
//                               to the app's Documents folder; the samples are bundled (sample = sample-plan).
//   -demoTapYes                 when a "Here is what I read" card appears, tap "Yes, right" by itself
//                               (once Agatha has stopped speaking, and at least 4 s after the card appeared)
//
// Existing call hooks (CallScheduler.swift): -testCall, -testCallAccept, -testFamilyCall.
// Full list with example commands per video scene: docs/demo-launch-args.md

/// The sheet the Pills tab opens by itself (from -demoSheet).
enum DemoSheet: String {
    case history, calendar
}

@MainActor
enum DemoLaunch {
    private static let args = ProcessInfo.processInfo.arguments

    private static func has(_ flag: String) -> Bool { args.contains(flag) }

    /// The argument after `flag`, e.g. "pills" for `-demoTab pills`.
    private static func value(_ flag: String) -> String? {
        guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    /// Called once from the app's first `.task`, before the call scheduler starts.
    static func run(model: ChatModel, navigator: Navigator) {
        if has("-demoReset") {
            model.deleteAllData()
            let name = DemoPerson.profile.address_as
            model.messages = [ChatMessage(role: .assistant,
                                          text: "Hello again, \(name)! Ask me what to take today, or show me a new letter.")]
        }

        let sheet = value("-demoSheet").flatMap(DemoSheet.init(rawValue:))
        if let sheet {
            navigator.demoSheet = sheet
            navigator.tab = .pills
        } else if let tab = value("-demoTab").flatMap(tab(named:)) {
            if tab == .talk { navigator.goHome() } else { navigator.tab = tab }
        }

        let delay = value("-demoAskDelay").flatMap(Double.init) ?? 2.5
        if let text = value("-demoAsk") {
            Task {
                try? await Task.sleep(for: .seconds(delay))
                navigator.tab = .talk
                await model.send(text: text)
            }
        }
        if let source = value("-demoScan") {
            Task {
                try? await Task.sleep(for: .seconds(delay))
                guard let image = image(from: source) else {
                    print("DemoLaunch: -demoScan could not load \(source)")
                    return
                }
                navigator.tab = .talk
                await model.send(text: "", image: image)
            }
        }
        if has("-demoTapYes") {
            Task { await tapYesWhenCardAppears(model: model) }
        }
    }

    private static func tab(named name: String) -> AppTab? {
        switch name.lowercased() {
        case "pills": .pills
        case "scan": .scan
        case "home", "talk": .talk
        case "notes": .notes
        case "sos": .sos
        default: nil
        }
    }

    /// A bundled sample, an absolute path, or a path inside the app's Documents folder.
    private static func image(from source: String) -> UIImage? {
        let bundled: String? = switch source {
        case "sample", "sample-plan": "medication-plan"
        case "sample-amlodipine": "medicine-box-new-amlodipine"
        default: nil
        }
        if let bundled {
            guard let url = Bundle.main.url(forResource: bundled, withExtension: "png") else { return nil }
            return UIImage(contentsOfFile: url.path)
        }
        let url = source.hasPrefix("/")
            ? URL(fileURLWithPath: source)
            : URL.documentsDirectory.appendingPathComponent(source)
        return UIImage(contentsOfFile: url.path)
    }

    /// Waits up to 3 minutes for an unanswered confirm card, then answers Yes.
    private static func tapYesWhenCardAppears(model: ChatModel) async {
        for _ in 0..<360 {
            try? await Task.sleep(for: .milliseconds(500))
            guard let (messageID, index) = unansweredConfirm(in: model) else { continue }
            try? await Task.sleep(for: .seconds(4))
            // Let Agatha finish reading the card out (answering stops her voice); give up waiting after 40 s.
            for _ in 0..<80 where model.isSpeaking || !model.canSend {
                try? await Task.sleep(for: .milliseconds(500))
            }
            try? await Task.sleep(for: .seconds(1))
            await model.answer(messageID: messageID, cardIndex: index, yes: true)
            return
        }
    }

    private static func unansweredConfirm(in model: ChatModel) -> (UUID, Int)? {
        for message in model.messages.reversed() where message.role == .assistant {
            if let i = message.cards.indices.first(where: {
                message.cards[$0].type.hasPrefix("confirm_") && message.answers[$0] == nil
            }) {
                return (message.id, i)
            }
        }
        return nil
    }
}
