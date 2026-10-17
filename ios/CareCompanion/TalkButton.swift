import SwiftUI
import UIKit

/// The huge round button that starts and stops listening. Also triggered by shaking the phone.
struct TalkButton: View {
    @EnvironmentObject private var model: ChatModel
    @State private var pulse = false
    @AppStorage("handsFree") private var handsFree = false

    /// In a tap-to-answer call it is the user's turn to answer; otherwise they start talking.
    private var idleLabel: String {
        model.isCallMode && !handsFree ? "Tap to answer" : "Tap to talk"
    }

    /// Red as soon as the user taps, not only once the microphone is running.
    private var active: Bool { model.isRecording || model.isStartingMic }

    var body: some View {
        Button(action: talk) {
            ZStack {
                // Soft pulsing ring so it is impossible to miss.
                Circle()
                    .fill((active ? Theme.Colors.danger : Theme.Colors.accent).opacity(Theme.Metrics.talkRingOpacity))
                    .scaleEffect(pulse ? Theme.Metrics.pulseMaxScale : Theme.Metrics.pulseMinScale)
                Circle()
                    .fill(active ? Theme.Colors.danger : Theme.Colors.accent)
                    .padding(Theme.Metrics.talkRingInset)
                    .shadow(radius: Theme.Metrics.talkShadowRadius, y: Theme.Metrics.talkShadowY)
                VStack(spacing: Theme.Metrics.spacingSmall) {
                    Image(systemName: active ? "stop.fill" : "mic.fill")
                        .font(Theme.Fonts.talkIcon)
                    Text(model.isRecording ? "I'm listening.\nTap when done" : model.isStartingMic ? "Getting ready…" : idleLabel)
                        .font(Theme.Fonts.talkLabel)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(Theme.Colors.onColor)
            }
            .frame(width: Theme.Metrics.talkButtonSize, height: Theme.Metrics.talkButtonSize)
        }
        .buttonStyle(.plain)
        .disabled(model.isBusy)
        .opacity(model.isBusy ? Theme.Metrics.busyOpacity : 1)
        .accessibilityLabel(model.isRecording ? "Stop listening" : "Talk to Agatha")
        .onAppear {
            withAnimation(.easeInOut(duration: Theme.Metrics.pulseDuration).repeatForever(autoreverses: true)) { pulse = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in talk() }
    }

    private func talk() {
        guard !model.isBusy else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        model.toggleRecording()
    }
}

// MARK: - First launch: the big "Start" button

/// Same size and weight as the talk button, so the first step is impossible to miss.
struct StartButton: View {
    @EnvironmentObject private var model: ChatModel
    @State private var pulse = false

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            model.startOnboarding()
        } label: {
            ZStack {
                Circle()
                    .fill(Theme.Colors.callGreen.opacity(Theme.Metrics.talkRingOpacity))
                    .scaleEffect(pulse ? Theme.Metrics.pulseMaxScale : Theme.Metrics.pulseMinScale)
                Circle()
                    .fill(Theme.Colors.callGreen)
                    .padding(Theme.Metrics.talkRingInset)
                    .shadow(radius: Theme.Metrics.talkShadowRadius, y: Theme.Metrics.talkShadowY)
                VStack(spacing: Theme.Metrics.spacingSmall) {
                    Image(systemName: "phone.fill")
                        .font(Theme.Fonts.talkIcon)
                    Text("Start")
                        .font(Theme.Fonts.startLabel)
                }
                .foregroundStyle(Theme.Colors.onColor)
            }
            .frame(width: Theme.Metrics.talkButtonSize, height: Theme.Metrics.talkButtonSize)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start getting to know each other")
        .onAppear {
            withAnimation(.easeInOut(duration: Theme.Metrics.pulseDuration).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}

// MARK: - Shake to talk

extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}
