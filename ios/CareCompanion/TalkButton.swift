import SwiftUI
import UIKit

/// Agatha herself is the talk button: tap the mascot to start and stop listening.
/// Also triggered by shaking the phone. Big in the hero, small in the header while chatting.
struct TalkButton: View {
    @EnvironmentObject private var model: ChatModel
    @State private var pulse = false
    @AppStorage("handsFree") private var handsFree = false
    /// Diameter of the white circle the mascot sits in.
    var circle: CGFloat = Theme.Metrics.mascotCircle
    /// Show the "Tap to talk" label under the mascot.
    var showLabel = true

    /// In a tap-to-answer call it is the user's turn to answer; otherwise they start talking.
    private var idleLabel: String {
        model.isCallMode && !handsFree ? "Tap Agatha to answer" : "Tap Agatha to talk"
    }

    /// Red as soon as the user taps, not only once the microphone is running.
    private var active: Bool { model.isRecording || model.isStartingMic }

    var label: String {
        model.isRecording ? "I'm listening. Tap when done" : model.isStartingMic ? "Getting ready…" : idleLabel
    }

    var body: some View {
        Button(action: talk) {
            VStack(spacing: Theme.Metrics.spacingLarge) {
                ZStack {
                    // Soft pulsing ring so it is impossible to miss.
                    Circle()
                        .fill((active ? Theme.Colors.danger : Theme.Palette.lavenderRing).opacity(active ? 0.35 : 0.55))
                        .frame(width: circle * 1.22, height: circle * 1.22)
                        .scaleEffect(pulse ? Theme.Metrics.pulseMaxScale : Theme.Metrics.pulseMinScale)
                    Circle()
                        .stroke(Theme.Colors.heroRing, lineWidth: 2)
                        .frame(width: circle * 1.4, height: circle * 1.4)
                        .opacity(circle > 120 ? 1 : 0)
                    Circle()
                        .fill(Theme.Palette.white)
                        .frame(width: circle, height: circle)
                        .overlay(Circle().stroke(active ? Theme.Colors.danger : .clear, lineWidth: circle > 120 ? 6 : 4))
                        .shadow(color: Theme.Colors.shadow, radius: circle * 0.1, y: circle * 0.05)
                    AgathaMascot(size: circle * 0.8)
                    if active {
                        Image(systemName: model.isRecording ? "waveform" : "ellipsis")
                            .font(.system(size: max(14, circle * 0.1), weight: .bold))
                            .foregroundStyle(Theme.Colors.onColor)
                            .padding(circle * 0.05)
                            .background(Theme.Colors.danger, in: Circle())
                            .symbolEffect(.variableColor.iterative, options: .repeating, isActive: model.isRecording)
                            .offset(x: circle * 0.36, y: -circle * 0.36)
                    }
                }
                .frame(width: max(circle * 1.4, Theme.Metrics.minTouch), height: max(circle * 1.4, Theme.Metrics.minTouch))
                if showLabel {
                    Text(label)
                        .font(Theme.Fonts.talkLabel)
                        .foregroundStyle(active ? Theme.Colors.danger : Theme.Palette.purpleDeep)
                        .multilineTextAlignment(.center)
                }
            }
            .contentShape(Rectangle())
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
