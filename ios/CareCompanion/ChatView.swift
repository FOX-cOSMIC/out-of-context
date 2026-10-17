import PhotosUI
import SwiftUI

/// One screen, one conversation: talk, show a photo, or type.
struct ChatView: View {
    @EnvironmentObject private var model: ChatModel
    @State private var typed = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showSettings = false
    @FocusState private var typing: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SkillsBar()
                conversation
                inputBar
            }
            .background(Theme.Colors.background)
            .navigationTitle("Agatha")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !model.showWelcome && !model.isCallMode {
                        Button { model.startCall() } label: {
                            Label("Call", systemImage: "phone.fill").labelStyle(.titleAndIcon).font(Theme.Fonts.headline)
                        }
                        .disabled(!model.canSend)
                        .accessibilityLabel("Start a call: talk hands-free")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape").font(Theme.Fonts.toolbarIcon)
                    }
                    .accessibilityLabel("Settings")
                }
            }
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
    }

    // MARK: - Messages

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Theme.Metrics.messageSpacing) {
                    if model.showWelcome { welcome }
                    ForEach(model.messages.filter { !$0.hidden }) { message in
                        MessageRow(message: message).id(message.id)
                    }
                    if model.isBusy {
                        HStack(spacing: Theme.Metrics.spacingRegular) {
                            ProgressView()
                            Text(model.status).foregroundStyle(Theme.Colors.textSecondary)
                        }
                        .font(Theme.Fonts.message)
                        .id("busy")
                    }
                }
                .padding(Theme.Metrics.screenPadding)
            }
            .onChange(of: model.messages.count) {
                withAnimation { proxy.scrollTo(model.messages.last?.id, anchor: .bottom) }
            }
            .onChange(of: model.isBusy) {
                if model.isBusy { withAnimation { proxy.scrollTo("busy", anchor: .bottom) } }
            }
        }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.spacingLarge) {
            Text("Hello! I'm Agatha.")
                .font(Theme.Fonts.welcomeTitle)
            Text("Let's get to know each other. Tap Start and I will ask you a few short questions out loud, like a phone call. Just answer in your own words.")
                .font(Theme.Fonts.message)
        }
        .padding(Theme.Metrics.welcomePadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Metrics.cornerLarge))
    }

    // MARK: - Talk / photo / type

    @ViewBuilder private var inputBar: some View {
        if model.showWelcome {
            VStack(spacing: Theme.Metrics.spacingRegular) {
                StartButton()
                Text("Tap Start to begin")
                    .font(Theme.Fonts.hint)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Metrics.screenPadding)
            .background(Theme.Colors.bar)
        } else {
            controls
        }
    }

    /// "Listening…" / "Thinking…" / "Speaking…" while a call is on.
    private var callLabel: String {
        if model.isRecording { return "Listening…" }
        if model.isBusy { return "Thinking…" }
        if model.isSpeaking { return "Speaking…" }
        return model.status.isEmpty ? "Tap to talk when you're ready" : model.status
    }

    private var controls: some View {
        VStack(spacing: Theme.Metrics.spacingRegular) {
            if model.isCallMode {
                HStack(spacing: Theme.Metrics.spacingLarge) {
                    Text(callLabel)
                        .font(Theme.Fonts.callStatus)
                        .foregroundStyle(model.isRecording ? Theme.Colors.danger : Theme.Colors.textPrimaryColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.updatesFrequently)
                    Button { model.endCall() } label: {
                        Label("End call", systemImage: "phone.down.fill")
                            .padding(.horizontal, Theme.Metrics.endCallHorizontalPadding)
                            .frame(minHeight: Theme.Metrics.bigButtonHeight)
                    }
                    .buttonStyle(BigButtonStyle(color: Theme.Colors.danger))
                }
            } else if !model.status.isEmpty && !model.isBusy {
                Text(model.status)
                    .font(Theme.Fonts.status)
                    .foregroundStyle(model.isRecording ? Theme.Colors.danger : Theme.Colors.textSecondaryColor)
                    .multilineTextAlignment(.center)
            }
            if !typing {
                TalkButton()
                if !model.isCallMode {
                    Text("Tap the button or shake your phone to talk")
                        .font(Theme.Fonts.hint)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                photoButton
            }
            typeField
        }
        .padding(Theme.Metrics.screenPadding)
        .background(Theme.Colors.bar)
    }

    private var photoButton: some View {
        Menu {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button { showCamera = true } label: { Label("Take a photo", systemImage: "camera") }
            }
            Button { showPhotoLibrary = true } label: { Label("Choose a photo", systemImage: "photo") }
        } label: {
            Label("Show me a photo", systemImage: "camera.fill")
                .frame(maxWidth: .infinity, minHeight: Theme.Metrics.bigButtonHeight)
        }
        .buttonStyle(BigButtonStyle(color: Theme.Colors.photoButton))
        .disabled(!model.canSend)
    }

    private var typeField: some View {
        HStack {
            TextField("Or type here", text: $typed, axis: .vertical)
                .font(Theme.Fonts.message)
                .padding(Theme.Metrics.fieldPadding)
                .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Metrics.cornerMedium))
                .submitLabel(.send)
                .focused($typing)
                .onSubmit(sendTyped)
                .disabled(!model.canSend)
            if !typed.isEmpty {
                Button(action: sendTyped) {
                    Image(systemName: "arrow.up.circle.fill").font(Theme.Fonts.sendIcon)
                }
                .disabled(!model.canSend)
                .accessibilityLabel("Send")
            }
            if typing {
                Button("Done") { typing = false }
                    .font(Theme.Fonts.headline)
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
                        .padding(Theme.Metrics.bubblePadding)
                        .background(Theme.Colors.userBubble, in: RoundedRectangle(cornerRadius: Theme.Metrics.cornerLarge))
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        } else {
            VStack(alignment: .leading, spacing: Theme.Metrics.spacingRegular) {
                if !message.text.isEmpty {
                    HStack(alignment: .top, spacing: Theme.Metrics.spacingRegular) {
                        Text(message.text)
                            .font(Theme.Fonts.message)
                            .padding(Theme.Metrics.bubblePadding)
                            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Metrics.cornerLarge))
                        Button { model.repeatAloud(message.text) } label: {
                            Image(systemName: "speaker.wave.2.fill").font(Theme.Fonts.repeatIcon)
                        }
                        .accessibilityLabel("Read it again")
                        .padding(.top, Theme.Metrics.repeatIconTopPadding)
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

// MARK: - Skills the user has practised

struct SkillsBar: View {
    @EnvironmentObject private var model: ChatModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.spacingSmall) {
            HStack {
                Text("Your AI skills").font(Theme.Fonts.headline)
                Spacer()
                Text("\(model.skills.count) of \(Skill.allCases.count)").font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textSecondary)
            }
            HStack(spacing: Theme.Metrics.spacingMedium) {
                ForEach(Skill.allCases, id: \.self) { skill in
                    let done = model.skills.contains(skill)
                    VStack(spacing: Theme.Metrics.spacingXSmall) {
                        Image(systemName: done ? "checkmark.circle.fill" : skill.icon)
                            .font(Theme.Fonts.skillIcon)
                            .foregroundStyle(done ? Theme.Colors.success : Theme.Colors.textSecondaryColor)
                        Text(skill.label)
                            .font(Theme.Fonts.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(done ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
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
        .background(Theme.Colors.bar)
    }
}

// MARK: - Shared button style

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
