import PhotosUI
import SwiftUI

/// The Talk tab: Agatha in a lavender hero when nothing is going on, the conversation once it starts.
/// Talk (tap Agatha or shake), show a photo, or type.
struct ChatView: View {
    @EnvironmentObject private var model: ChatModel
    @EnvironmentObject private var navigator: Navigator
    /// The Home button was tapped: show the big home screen even if a conversation exists.
    @State private var homeShown = false
    @State private var typed = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showSettings = false
    @FocusState private var typing: Bool

    private var visibleMessages: [ChatMessage] { model.messages.filter { !$0.hidden } }

    /// Something is going on: then the hero shrinks to a small header so the messages have room.
    /// The single "Hello again" greeting alone does not count; the hero says hello instead.
    private var inConversation: Bool {
        visibleMessages.count > 1 || visibleMessages.contains { $0.role == .user }
            || model.liveText != nil || model.isBusy || model.isCallMode
    }

    /// Conversation view, unless the user went Home; while talking or thinking it always shows.
    private var showConversation: Bool {
        (inConversation && !homeShown) || model.isBusy || model.isRecording
            || model.liveText != nil || model.isCallMode
    }

    /// Earlier messages exist that the user can go back to from the home screen.
    private var hasEarlierConversation: Bool {
        visibleMessages.contains { $0.role == .user }
    }

    /// How the user likes to be called: address_as, else name, else nothing.
    private var userName: String {
        let p = model.profile
        return p.address_as.isEmpty ? p.name : p.address_as
    }

    var body: some View {
        VStack(spacing: 0) {
            if model.showWelcome {
                welcomeScreen
            } else {
                // One simple screen: Agatha, what you said, her answer (and its card).
                homeScreen
            }
        }
        .background(Theme.Colors.background)
        .animation(.easeInOut(duration: 0.3), value: showConversation)
        .onChange(of: navigator.homeTick) { homeShown = true }
        .onChange(of: model.messages.count) { homeShown = false }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in Task { await model.send(text: "", image: image) } }
                .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showPhotoLibrary, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            photoItem = nil
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    await model.send(text: "", image: image)
                }
            }
        }
    }

    // MARK: - Hero (home of the Talk tab)

    private var homeScreen: some View {
        ScrollView {
            VStack(spacing: Theme.Metrics.spacingLarge) {
                hero { TalkButton(circle: 190, showLabel: false) }
                currentTurn
                    .padding(.horizontal, Theme.Metrics.screenPadding)
                    .padding(.top, -36) // tuck it up into the white cloud edge
                Spacer(minLength: Theme.Metrics.screenPadding)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(alignment: .top) { heroBackdrop }
    }

    // MARK: - One screen only: what is happening right now, under Agatha (no chat history)

    private var lastUser: ChatMessage? { visibleMessages.last { $0.role == .user } }
    private var lastAgatha: ChatMessage? { visibleMessages.last { $0.role == .assistant } }
    private var talking: Bool { model.isRecording || model.isStartingMic }

    @ViewBuilder private var currentTurn: some View {
        VStack(spacing: Theme.Metrics.spacingLarge) {
            if talking {
                Text(TalkButtonLabel.text(model))
                    .font(Theme.Fonts.heroTitle)
                    .foregroundStyle(Theme.Colors.danger)
                if let words = model.liveText, !words.isEmpty {
                    Text("“\(words)”")
                        .font(Theme.Fonts.message)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            } else if model.isBusy {
                if let said = lastUser?.text, !said.isEmpty {
                    Text("“\(said)”").font(Theme.Fonts.hint).foregroundStyle(Theme.Colors.textSecondary)
                }
                HStack(spacing: Theme.Metrics.spacingRegular) {
                    ProgressView().tint(Theme.Colors.accent)
                    Text("Thinking…")
                }
                .font(Theme.Fonts.heroGreeting)
                .foregroundStyle(Theme.Colors.textSecondary)
            } else if hasEarlierConversation, let answer = lastAgatha {
                if let said = lastUser?.text, !said.isEmpty {
                    Text("You: “\(said)”").font(Theme.Fonts.hint).foregroundStyle(Theme.Colors.textSecondary)
                }
                MessageRow(message: answer)
                Text("Tap Agatha to talk").font(Theme.Fonts.hint).foregroundStyle(Theme.Colors.textSecondary)
            } else {
                VStack(spacing: Theme.Metrics.spacingSmall) {
                    Text(userName.isEmpty ? "Hello!" : "Hello \(userName)!")
                        .font(Theme.Fonts.heroGreeting)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Text("How are you doing today?")
                        .font(Theme.Fonts.heroTitle)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("Tap Agatha to talk")
                        .font(Theme.Fonts.hint)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            if !model.status.isEmpty && !model.isBusy && !talking {
                Text(model.status).font(Theme.Fonts.status).foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    /// Lavender behind the status bar and the top of the hero, white under the cloud edge.
    private var heroBackdrop: some View {
        VStack(spacing: 0) {
            Theme.Colors.hero.frame(height: 300)
            Theme.Palette.white
        }
        .ignoresSafeArea()
    }

    /// Lavender hero with the "MEDICINE HELPER" chip, flowers and a soft cloud edge.
    private func hero<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack(alignment: .top) {
            Theme.Colors.hero
            Image("HeroFlowers")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .accessibilityHidden(true)
            VStack(spacing: Theme.Metrics.spacingLarge) {
                content()
            }
            .padding(.top, Theme.Metrics.spacingMedium)
            topButtons
        }
        .frame(height: 360)
    }

    /// Call (top left) and Settings (top right).
    private var topButtons: some View {
        HStack {
            Spacer()
            // Tap-to-talk only: no call button. Settings stays small and quiet (needed to reset a demo).
            Button { showSettings = true } label: {
                Image(systemName: "gearshape").font(Theme.Fonts.toolbarIcon)
                    .frame(width: Theme.Metrics.minTouch, height: Theme.Metrics.minTouch)
                    .opacity(0.6)
            }
            .accessibilityLabel("Settings")
        }
        .foregroundStyle(Theme.Palette.purpleDeep)
        .padding(.horizontal, Theme.Metrics.screenPadding)
    }

    // MARK: - First launch

    private var welcomeScreen: some View {
        ScrollView {
            VStack(spacing: Theme.Metrics.spacingLarge) {
                hero { MascotBadge(circle: 190) }
                VStack(spacing: Theme.Metrics.spacingMedium) {
                    Text("Hello! I'm Agatha.")
                        .font(Theme.Fonts.welcomeTitle)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("Let's get to know each other. Tap Start and I will ask you a few short questions out loud, like a phone call. Just answer in your own words.")
                        .font(Theme.Fonts.message)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Metrics.screenPadding)
                StartButton()
                Text("Tap Start to begin")
                    .font(Theme.Fonts.hint)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.bottom, Theme.Metrics.screenPadding)
            }
        }
        .background(alignment: .top) { heroBackdrop }
    }

    // MARK: - Conversation

    /// Small mascot (still the talk button), Agatha's name and what she is doing.
    private var compactHeader: some View {
        HStack(spacing: Theme.Metrics.spacingLarge) {
            TalkButton(circle: Theme.Metrics.mascotCircleSmall, showLabel: false)
            VStack(alignment: .leading, spacing: Theme.Metrics.spacingTiny) {
                Text("Agatha").font(Theme.Fonts.cardTitle).foregroundStyle(Theme.Colors.textPrimary)
                Text(headerStatus)
                    .font(Theme.Fonts.status)
                    .foregroundStyle(model.isRecording || model.isStartingMic ? Theme.Colors.danger : Theme.Palette.purpleDeep)
                    .lineLimit(2)
                    .accessibilityAddTraits(.updatesFrequently)
            }
            Spacer(minLength: 0)
            topButtons.padding(.horizontal, -Theme.Metrics.screenPadding).fixedSize()
        }
        .padding(.horizontal, Theme.Metrics.screenPadding)
        .padding(.vertical, Theme.Metrics.spacingSmall)
        .background(Theme.Colors.hero, in: UnevenRoundedRectangle(bottomLeadingRadius: 28, bottomTrailingRadius: 28))
        // Lavender also behind the status bar, without hiding the rounded bottom corners.
        .background(alignment: .top) { Theme.Colors.hero.frame(height: 40).ignoresSafeArea(edges: .top) }
    }

    /// "I'm listening" / "Thinking…" / "Speaking…" / "Tap me to talk".
    private var headerStatus: String {
        if model.isRecording || model.isStartingMic { return TalkButtonLabel.text(model) }
        if model.isBusy { return "Thinking…" }
        if model.isSpeaking { return "Speaking…" }
        if model.isCallMode { return model.status.isEmpty ? model.yourTurnStatus : model.status }
        return model.status.isEmpty ? "Tap me to talk" : model.status
    }

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Theme.Metrics.messageSpacing) {
                    ForEach(visibleMessages) { message in
                        MessageRow(message: message).id(message.id)
                    }
                    if let words = model.liveText {
                        LiveBubble(words: words, listening: model.isRecording).id("live")
                    }
                    if model.isBusy {
                        HStack(spacing: Theme.Metrics.spacingRegular) {
                            ProgressView().tint(Theme.Colors.accent)
                            Text(model.status).foregroundStyle(Theme.Colors.textSecondary)
                        }
                        .font(Theme.Fonts.message)
                        .id("busy")
                    }
                }
                .padding(Theme.Metrics.screenPadding)
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear { proxy.scrollTo(model.messages.last?.id, anchor: .bottom) }
            .onChange(of: model.messages.count) {
                withAnimation { proxy.scrollTo(model.messages.last?.id, anchor: .bottom) }
            }
            .onChange(of: model.isBusy) {
                if model.isBusy { withAnimation { proxy.scrollTo("busy", anchor: .bottom) } }
            }
            .onChange(of: model.liveText) {
                if model.liveText != nil { proxy.scrollTo("live", anchor: .bottom) }
            }
        }
    }

    // MARK: - Call / photo / type

    private var controls: some View {
        VStack(spacing: Theme.Metrics.spacingRegular) {
            if model.isCallMode {
                Button { model.endCall() } label: {
                    Label("End call", systemImage: "phone.down.fill")
                        .frame(maxWidth: .infinity, minHeight: Theme.Metrics.bigButtonHeight)
                }
                .buttonStyle(BigButtonStyle(color: Theme.Colors.danger))
            }
            HStack(spacing: Theme.Metrics.spacingMedium) {
                if !typing { photoButton }
                typeField
            }
        }
        .padding(.horizontal, Theme.Metrics.screenPadding)
        .padding(.vertical, Theme.Metrics.spacingMedium)
        .background(Theme.Colors.bar)
    }

    private var photoButton: some View {
        Menu {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button { showCamera = true } label: { Label("Take a photo", systemImage: "camera") }
            }
            Button { showPhotoLibrary = true } label: { Label("Choose a photo", systemImage: "photo") }
        } label: {
            Image(systemName: "camera.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.Colors.onColor)
                .frame(width: Theme.Metrics.bigButtonHeight, height: Theme.Metrics.bigButtonHeight)
                .background(Theme.Colors.photoButton, in: RoundedRectangle(cornerRadius: Theme.Metrics.cornerMedium))
        }
        .disabled(!model.canSend)
        .opacity(model.canSend ? 1 : Theme.Metrics.disabledOpacity)
        .accessibilityLabel("Show me a photo")
    }

    private var typeField: some View {
        HStack(spacing: Theme.Metrics.spacingMedium) {
            TextField("Or type here", text: $typed, axis: .vertical)
                .font(Theme.Fonts.message)
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(Theme.Metrics.fieldPadding)
                .frame(minHeight: Theme.Metrics.bigButtonHeight)
                .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Metrics.cornerMedium))
                .overlay(RoundedRectangle(cornerRadius: Theme.Metrics.cornerMedium).stroke(Theme.Colors.cardBorder, lineWidth: 1.5))
                .submitLabel(.send)
                .focused($typing)
                .onSubmit(sendTyped)
                .disabled(!model.canSend)
            if !typed.isEmpty {
                Button(action: sendTyped) {
                    Image(systemName: "arrow.up.circle.fill").font(Theme.Fonts.sendIcon).foregroundStyle(Theme.Colors.accent)
                }
                .disabled(!model.canSend)
                .accessibilityLabel("Send")
            }
            if typing {
                Button("Done") { typing = false }
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(minHeight: Theme.Metrics.minTouch)
            }
        }
    }

    private func sendTyped() {
        guard model.canSend else { return }
        let text = typed
        typed = ""
        typing = false
        Task { await model.send(text: text) }
    }
}

/// The words the talk control shows, shared by the hero title and the header.
enum TalkButtonLabel {
    @MainActor static func text(_ model: ChatModel) -> String {
        model.isRecording ? "I'm listening…" : "Getting ready…"
    }
}

// MARK: - One message with its cards

struct MessageRow: View {
    @EnvironmentObject private var model: ChatModel
    let message: ChatMessage

    var body: some View {
        if message.role == .user {
            VStack(alignment: .trailing, spacing: Theme.Metrics.spacingMedium) {
                if let image = message.image {
                    Image(uiImage: image)
                        .resizable().scaledToFit()
                        .frame(maxHeight: Theme.Metrics.photoMaxHeight)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.cornerMedium))
                }
                if !message.text.isEmpty {
                    Text(message.text)
                        .font(Theme.Fonts.message)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .padding(Theme.Metrics.bubblePadding)
                        .background(Theme.Colors.userBubble, in: UnevenRoundedRectangle(topLeadingRadius: Theme.Metrics.cornerLarge, bottomLeadingRadius: Theme.Metrics.cornerLarge, bottomTrailingRadius: 6, topTrailingRadius: Theme.Metrics.cornerLarge))
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        } else {
            VStack(alignment: .leading, spacing: Theme.Metrics.spacingRegular) {
                if !message.text.isEmpty {
                    HStack(alignment: .top, spacing: Theme.Metrics.spacingRegular) {
                        Text(message.text)
                            .font(Theme.Fonts.message)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .padding(Theme.Metrics.bubblePadding)
                            .background(Theme.Colors.surface, in: UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: Theme.Metrics.cornerLarge, bottomTrailingRadius: Theme.Metrics.cornerLarge, topTrailingRadius: Theme.Metrics.cornerLarge))
                            .shadow(color: Theme.Colors.shadow, radius: 10, y: 4)
                        Button { model.repeatAloud(message.text) } label: {
                            Image(systemName: "speaker.wave.2.fill").font(Theme.Fonts.repeatIcon)
                                .foregroundStyle(Theme.Colors.accent)
                                .frame(width: Theme.Metrics.minTouch, height: Theme.Metrics.minTouch)
                                .background(Theme.Palette.lavenderLight, in: Circle())
                        }
                        .accessibilityLabel("Read it again")
                        .padding(.top, Theme.Metrics.spacingXSmall)
                    }
                }
                ForEach(Array(message.cards.enumerated()), id: \.offset) { index, card in
                    CardView(card: card, messageID: message.id, cardIndex: index, answer: message.answers[index])
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - What Agatha hears, while the user is still talking

struct LiveBubble: View {
    let words: String
    /// Still listening (false: finished, the last words are being written down).
    let listening: Bool

    var body: some View {
        VStack(alignment: .trailing, spacing: Theme.Metrics.spacingXSmall) {
            if listening {
                Label("Listening…", systemImage: "waveform")
                    .font(Theme.Fonts.liveIndicator)
                    .foregroundStyle(Theme.Colors.liveIndicator)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
            }
            Text(words.isEmpty ? "…" : words)
                .font(Theme.Fonts.message)
                .foregroundStyle(Theme.Colors.textPrimary)
                .opacity(Theme.Metrics.liveTextOpacity)
                .padding(Theme.Metrics.bubblePadding)
                .background(Theme.Colors.liveBubble, in: RoundedRectangle(cornerRadius: Theme.Metrics.cornerLarge))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Metrics.cornerLarge)
                        .stroke(Theme.Colors.liveBubbleBorder,
                                style: StrokeStyle(lineWidth: Theme.Metrics.liveBubbleBorderWidth, dash: [Theme.Metrics.liveBubbleDash]))
                )
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(words.isEmpty ? "Listening" : "Agatha hears: \(words)")
    }
}

// MARK: - Skills the user has practised

/// Compact strip: the four AI skills Agatha teaches, ticked off as the user practises them.
struct SkillsBar: View {
    @EnvironmentObject private var model: ChatModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.spacingSmall) {
            HStack {
                Label("Your AI skills", systemImage: "sparkles")
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.Palette.purpleDeep)
                Spacer()
                Text("\(model.skills.count) of \(Skill.allCases.count)")
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            HStack(spacing: Theme.Metrics.spacingSmall) {
                ForEach(Skill.allCases, id: \.self) { skill in
                    let done = model.skills.contains(skill)
                    VStack(spacing: Theme.Metrics.spacingTiny) {
                        Image(systemName: done ? "checkmark.circle.fill" : skill.icon)
                            .font(Theme.Fonts.skillIcon)
                            .foregroundStyle(done ? Theme.Colors.success : Theme.Palette.purple)
                        Text(skill.label)
                            .font(Theme.Fonts.caption)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(done ? Theme.Colors.success : Theme.Palette.inkMuted)
                    }
                    .padding(.vertical, Theme.Metrics.spacingSmall)
                    .padding(.horizontal, Theme.Metrics.spacingXSmall)
                    .frame(maxWidth: .infinity, minHeight: Theme.Metrics.minTouch)
                    .background(done ? Theme.Palette.mint : Theme.Palette.lavenderLight,
                                in: RoundedRectangle(cornerRadius: Theme.Metrics.cornerSmall))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(skill.label), \(done ? "done" : "not yet")")
                }
            }
            if let learned = model.lastLearned {
                Text("New skill: \(learned.label)! 🎉")
                    .font(Theme.Fonts.celebration)
                    .foregroundStyle(Theme.Colors.success)
                    .task(id: learned) {
                        try? await Task.sleep(for: .seconds(4))
                        model.lastLearned = nil
                    }
            }
        }
        .padding(.horizontal, Theme.Metrics.screenPadding)
        .padding(.vertical, Theme.Metrics.skillsBarVerticalPadding)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Metrics.cornerLarge))
        .shadow(color: Theme.Colors.shadow, radius: 8, y: 3)
        .padding(.horizontal, Theme.Metrics.spacingMedium)
        .padding(.top, Theme.Metrics.spacingMedium)
    }
}

// MARK: - Shared button styles

/// White button with a lavender outline, for the quieter choice ("No").
struct SoftButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Fonts.buttonLabel)
            .foregroundStyle(Theme.Palette.purpleDeep)
            .background(Theme.Palette.white, in: RoundedRectangle(cornerRadius: Theme.Metrics.cornerLarge))
            .overlay(RoundedRectangle(cornerRadius: Theme.Metrics.cornerLarge).stroke(Theme.Colors.cardBorder, lineWidth: Theme.Metrics.cardBorderWidth))
            .opacity(isEnabled ? (configuration.isPressed ? Theme.Metrics.pressedOpacity : 1) : Theme.Metrics.disabledOpacity)
    }
}

struct BigButtonStyle: ButtonStyle {
    var color: Color
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Fonts.buttonLabel)
            .foregroundStyle(Theme.Colors.onColor)
            .background(color.opacity(isEnabled ? (configuration.isPressed ? Theme.Metrics.pressedOpacity : 1) : Theme.Metrics.disabledOpacity),
                        in: RoundedRectangle(cornerRadius: Theme.Metrics.cornerLarge))
    }
}
