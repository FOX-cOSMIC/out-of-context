import SwiftUI
import UIKit

/// The huge round button that starts and stops listening. Also triggered by shaking the phone.
struct TalkButton: View {
    @EnvironmentObject private var model: ChatModel
    @State private var pulse = false

    var body: some View {
        Button(action: talk) {
            ZStack {
                // Soft pulsing ring so it is impossible to miss.
                Circle()
                    .fill((model.isRecording ? Color.red : Color.accentColor).opacity(0.25))
                    .scaleEffect(pulse ? 1.12 : 0.96)
                Circle()
                    .fill(model.isRecording ? Color.red : Color.accentColor)
                    .padding(14)
                    .shadow(radius: 8, y: 4)
                VStack(spacing: 6) {
                    Image(systemName: model.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 64, weight: .bold))
                    Text(model.isRecording ? "I'm listening.\nTap when done" : "Tap to talk")
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.white)
            }
            .frame(width: 230, height: 230)
        }
        .buttonStyle(.plain)
        .disabled(model.isBusy)
        .opacity(model.isBusy ? 0.5 : 1)
        .accessibilityLabel(model.isRecording ? "Stop listening" : "Talk to Care Companion")
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { pulse = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in talk() }
    }

    private func talk() {
        guard !model.isBusy else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        model.toggleRecording()
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
