import SwiftUI
import UIKit

/// Agatha's simulated medication-reminder call, styled like the iPhone's own call screen.
/// Shown in its own window above everything (tab bar, sheets), see `CallWindow`.
struct IncomingCallView: View {
    @EnvironmentObject private var scheduler: CallScheduler

    var body: some View {
        ZStack {
            if let call = scheduler.activeCall {
                switch call.state {
                case .ringing: RingingCallView(call: call)
                case .connected: ConnectedCallView(call: call)
                case .callingFamily: FamilyCallView(call: call)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: scheduler.activeCall?.state)
    }
}

// MARK: - Shared look

/// The dark, softly coloured background of the iOS call screen.
private struct CallBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x2A1B5C), Color(hex: 0x140D2E), Color(hex: 0x07060F)],
                           startPoint: .top, endPoint: .bottom)
            Circle().fill(Theme.Palette.purple.opacity(0.45)).frame(width: 420).blur(radius: 120).offset(x: -80, y: -260)
            Circle().fill(Color(hex: 0xF08A3C).opacity(0.18)).frame(width: 300).blur(radius: 110).offset(x: 140, y: 120)
        }
        .ignoresSafeArea()
    }
}

/// A big round call button with its label underneath (Decline / Accept).
/// A tap gesture rather than a SwiftUI Button: in the Simulator an active audio session made
/// SwiftUI fire the Accept button by itself.
private struct RoundCallButton: View {
    var label: String
    var icon: String
    var color: Color
    var size: CGFloat = 76
    var action: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(color, in: Circle())
            Text(label)
                .font(Theme.Typeface.body(20, weight: .bold))
                .foregroundStyle(.white)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            action()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { action() }
    }
}

private enum CallColors {
    static let red = Color(hex: 0xEB4E3D)
    static let green = Color(hex: 0x34C759)
    static let tick = Color(hex: 0x6EE7A0)
}

/// "00:12", "1:02:05"
private func elapsed(from start: Date, to now: Date) -> String {
    let total = max(0, Int(now.timeIntervalSince(start)))
    let (h, m, s) = (total / 3600, total / 60 % 60, total % 60)
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
}

// MARK: - Ringing

private struct RingingCallView: View {
    @EnvironmentObject private var scheduler: CallScheduler
    let call: CallInfo
    @State private var pulse = false

    var body: some View {
        ZStack {
            CallBackground()
            VStack(spacing: 0) {
                Text(call.attemptLabel ?? "Phone call")
                    .font(Theme.Typeface.body(19, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 24)

                Spacer(minLength: 16)

                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.35), lineWidth: 3)
                        .frame(width: 190, height: 190)
                        .scaleEffect(pulse ? 1.35 : 1)
                        .opacity(pulse ? 0 : 1)
                    Circle()
                        .stroke(.white.opacity(0.25), lineWidth: 2)
                        .frame(width: 190, height: 190)
                        .scaleEffect(pulse ? 1.15 : 0.95)
                    MascotBadge(circle: 170, showRings: false)
                }
                .frame(height: 260)
                .onAppear {
                    withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) { pulse = true }
                }

                Text("Agatha")
                    .font(Theme.Typeface.heading(52))
                    .foregroundStyle(.white)
                    .padding(.top, 20)
                Text("Medication reminder")
                    .font(Theme.Typeface.body(24))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 4)
                Text("\(call.dueTime) · \(call.detail)")
                    .font(Theme.Typeface.body(19))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 12)

                Spacer(minLength: 24)

                HStack {
                    RoundCallButton(label: "Decline", icon: "phone.down.fill", color: CallColors.red) {
                        scheduler.decline()
                    }
                    Spacer()
                    RoundCallButton(label: "Accept", icon: "phone.fill", color: CallColors.green) {
                        scheduler.accept()
                    }
                }
                .padding(.horizontal, 56)
                .padding(.bottom, 40)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Agatha is calling: \(call.detail)")
    }
}

// MARK: - In the call (hands-free conversation + pill checklist)

/// Top to bottom: who and how long, what the call is for, live captions of both sides, the pills
/// to tick off (scrolls), End call. Hands-free: the conversation runs in ChatModel (onAccepted),
/// which listens by itself after Agatha speaks.
private struct ConnectedCallView: View {
    @EnvironmentObject private var scheduler: CallScheduler
    @EnvironmentObject private var model: ChatModel
    let call: CallInfo

    private var visible: [ChatMessage] { model.messages.filter { !$0.hidden && !$0.isError } }
    /// What Agatha said last (shown big, so the call works without hearing every word).
    private var lastAgatha: String? { visible.last { $0.role == .assistant }?.text }
    /// The user's last words, if they came after Agatha's last line.
    private var lastUser: String? {
        guard let last = visible.last, last.role == .user, !last.text.isEmpty else { return nil }
        return last.text
    }
    private var listening: Bool { model.isRecording || model.isStartingMic }

    private var stateLine: String {
        if call.isConfirmed { return "Thank you! Ending the call…" }
        if listening { return "Listening…" }
        if model.isBusy { return "Thinking…" }
        if model.isSpeaking { return "Agatha is speaking…" }
        return "Connected"
    }

    var body: some View {
        ZStack {
            CallBackground()
            VStack(spacing: 12) {
                header
                purposeCard
                captions
                checklist
                endButton
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            MascotBadge(circle: 52, showRings: false)
            VStack(alignment: .leading, spacing: 0) {
                Text("Agatha")
                    .font(Theme.Typeface.heading(28))
                    .foregroundStyle(.white)
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(elapsed(from: call.connectedAt ?? context.date, to: context.date))
                        .font(Theme.Typeface.body(18).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            Spacer()
            Text(stateLine)
                .font(Theme.Typeface.body(17, weight: .bold))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.trailing)
        }
    }

    /// What the call is for, and whether the user confirmed taking the pills.
    private var purposeCard: some View {
        HStack(spacing: 12) {
            Image(systemName: call.isConfirmed ? "checkmark.circle.fill" : "pills.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(call.isConfirmed ? CallColors.tick : .white)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(call.slotTitle) · \(call.dueTime)")
                    .font(Theme.Typeface.heading(23))
                Text(call.isConfirmed ? "Confirmed ✓" : "Waiting for your confirmation")
                    .font(Theme.Typeface.body(18, weight: .bold))
                    .foregroundStyle(call.isConfirmed ? CallColors.tick : .white.opacity(0.75))
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(.white.opacity(call.isConfirmed ? 0.16 : 0.10), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(call.isConfirmed ? CallColors.green : .white.opacity(0.18), lineWidth: call.isConfirmed ? 2 : 1))
        .animation(.easeInOut, value: call.isConfirmed)
        .accessibilityElement(children: .combine)
    }

    /// Agatha's line big; the user's live words while listening, or "You said: …" afterwards.
    private var captions: some View {
        ScrollView {
            VStack(spacing: 10) {
                if let lastAgatha {
                    Text(lastAgatha)
                        .font(Theme.Typeface.body(22))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.75)
                }
                if listening {
                    Text((model.liveText ?? "").isEmpty ? "Listening…" : "“\(model.liveText ?? "")”")
                        .font(Theme.Typeface.body(20))
                        .foregroundStyle(Color(hex: 0xD9CCFF))
                } else if let lastUser {
                    Text("You said: \(lastUser)")
                        .font(Theme.Typeface.body(19))
                        .foregroundStyle(Color(hex: 0xD9CCFF))
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
        .defaultScrollAnchor(.top) // read Agatha's sentence from its beginning
        .frame(maxHeight: 210)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// Every medicine due in this slot, with a big checkbox each.
    private var checklist: some View {
        let meds = scheduler.medicines(call.slot)
        return VStack(spacing: 6) {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(meds) { med in
                        pillRow(med)
                    }
                    if meds.isEmpty {
                        Text("No medicines are planned for this time.")
                            .font(Theme.Typeface.body(19))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            .frame(maxHeight: .infinity)
            if !call.isConfirmed, !meds.isEmpty {
                Button {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    scheduler.confirmAll(slot: call.slot)
                } label: {
                    Text("Confirm all")
                        .font(Theme.Typeface.body(18, weight: .bold))
                        .foregroundStyle(.white)
                        .underline()
                        .frame(minHeight: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Confirm I've taken all of them")
            }
        }
    }

    private func pillRow(_ med: Medication) -> some View {
        let taken = model.isTaken(med, slot: call.slot) || call.isConfirmed
        let dose = med.times.dose(for: call.slot)
        return Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            scheduler.toggle(med, slot: call.slot)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(taken ? CallColors.green : .white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(taken ? CallColors.green : .white.opacity(0.7), lineWidth: 2.5)
                    if taken {
                        Image(systemName: "checkmark").font(.system(size: 28, weight: .heavy)).foregroundStyle(.white)
                    }
                }
                .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text([CallScheduler.shortName(med.name), med.strength].filter { !$0.isEmpty }.joined(separator: " "))
                        .font(Theme.Typeface.body(21, weight: .bold))
                    Text(dose == "1" ? "1 tablet" : "\(dose) tablets")
                        .font(Theme.Typeface.body(18))
                        .opacity(0.85)
                    if !med.instructions.isEmpty {
                        Text(med.instructions)
                            .font(Theme.Typeface.body(18))
                            .foregroundStyle(Color(hex: 0xFFD7A8))
                    }
                }
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(.white.opacity(taken ? 0.14 : 0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(call.isConfirmed)
        .accessibilityLabel("\(med.name) \(med.strength), \(med.instructions)")
        .accessibilityValue(taken ? "taken" : "not taken")
    }

    private var endButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            scheduler.endCall()
        } label: {
            Label("End call", systemImage: "phone.down.fill")
                .font(Theme.Typeface.heading(22))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(CallColors.red.opacity(0.9), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("End call")
    }
}

// MARK: - Calling the family helper (after the last unconfirmed try)

/// "Calling Anna (your daughter)" with a ring-back tone for ~5 s, then "Connected" and what she was
/// told, then "Anna has been informed ✓" with OK. Simulated: no real call is made.
private struct FamilyCallView: View {
    @EnvironmentObject private var scheduler: CallScheduler
    @EnvironmentObject private var model: ChatModel
    let call: CallInfo

    private enum Phase { case calling, connected, informed }
    @State private var phase = Phase.calling
    @State private var pulse = false

    private var name: String {
        model.profile.helper_name.isEmpty ? "your family helper" : model.profile.helper_name
    }
    private var relation: String? {
        let r = model.profile.helper_relation
        return model.profile.helper_name.isEmpty || r.isEmpty ? nil : "your \(r)"
    }
    /// "Anna" / "Your family helper" (at the start of a sentence).
    private var displayName: String { name.prefix(1).uppercased() + name.dropFirst() }
    private var initial: String {
        model.profile.helper_name.first.map { String($0).uppercased() } ?? "?"
    }

    var body: some View {
        ZStack {
            CallBackground()
            VStack(spacing: 0) {
                Text("Agatha couldn't reach you")
                    .font(Theme.Typeface.body(19, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 24)

                Spacer(minLength: 16)

                ZStack {
                    if phase == .calling {
                        Circle()
                            .stroke(.white.opacity(0.35), lineWidth: 3)
                            .frame(width: 170, height: 170)
                            .scaleEffect(pulse ? 1.35 : 1)
                            .opacity(pulse ? 0 : 1)
                    }
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: 0xF0A35E), Color(hex: 0xD9733A)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 150, height: 150)
                    Text(initial)
                        .font(Theme.Typeface.heading(70))
                        .foregroundStyle(.white)
                    if phase == .informed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.white, CallColors.green)
                            .offset(x: 56, y: 56)
                    }
                }
                .frame(height: 230)
                .onAppear {
                    withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) { pulse = true }
                }

                Text(phase == .calling ? "Calling \(name)" : displayName)
                    .font(Theme.Typeface.heading(40))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                if let relation {
                    Text("(\(relation))")
                        .font(Theme.Typeface.body(22))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.top, 2)
                }

                Group {
                    switch phase {
                    case .calling:
                        Text("Ringing…")
                    case .connected:
                        Text("Connected\n\n\(displayName) has been told you haven't confirmed your \(call.slot.rawValue) pills.")
                    case .informed:
                        Text("\(displayName) has been informed ✓")
                            .foregroundStyle(CallColors.tick)
                    }
                }
                .font(Theme.Typeface.body(23, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.top, 24)

                Spacer(minLength: 24)

                if phase == .informed {
                    Button {
                        scheduler.endCall()
                    } label: {
                        Text("OK")
                            .font(Theme.Typeface.heading(26))
                            .foregroundStyle(Theme.Palette.purpleDeep)
                            .frame(maxWidth: .infinity, minHeight: 68)
                            .background(.white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 28)
                } else {
                    Image(systemName: "phone.down.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 76, height: 76)
                        .background(CallColors.red.opacity(0.5), in: Circle())
                        .accessibilityHidden(true)
                }

                Text("Demo: no real call is made.")
                    .font(Theme.Typeface.body(16))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.top, 14)
                    .padding(.bottom, 20)
            }
            .animation(.easeInOut(duration: 0.4), value: phase)
        }
        .task {
            scheduler.startOutgoingTone()
            try? await Task.sleep(for: .seconds(5))
            scheduler.stopOutgoingTone()
            phase = .connected
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            try? await Task.sleep(for: .seconds(3))
            phase = .informed
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        .onDisappear { scheduler.stopOutgoingTone() }
    }
}

// MARK: - Its own window, above sheets and the tab bar

/// Shows IncomingCallView in a separate window at alert level, so it covers everything
/// (even an open Settings sheet) like a real incoming call. RootView shows/hides it.
@MainActor
enum CallWindow {
    private static var window: UIWindow?

    static func show(scheduler: CallScheduler, model: ChatModel) {
        guard window == nil,
              let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }) ??
                UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
        else { return }
        let host = UIHostingController(rootView: IncomingCallView()
            .environmentObject(scheduler)
            .environmentObject(model))
        host.view.backgroundColor = .clear
        let win = UIWindow(windowScene: scene)
        win.windowLevel = .alert + 1
        win.overrideUserInterfaceStyle = .dark // white status bar on the dark call screen
        win.rootViewController = host
        win.alpha = 0
        win.makeKeyAndVisible()
        UIView.animate(withDuration: 0.25) { win.alpha = 1 }
        window = win
    }

    static func hide() {
        guard let win = window else { return }
        window = nil
        UIView.animate(withDuration: 0.25, animations: { win.alpha = 0 }) { _ in
            win.isHidden = true
            win.windowScene?.windows.first { $0 !== win && $0.windowLevel == .normal }?.makeKey()
        }
    }
}

