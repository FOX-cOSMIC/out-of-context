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
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Care Companion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !model.showWelcome && !model.isCallMode {
                        Button { model.startCall() } label: {
                            Label("Call", systemImage: "phone.fill").labelStyle(.titleAndIcon).font(.headline)
                        }
                        .disabled(!model.canSend)
                        .accessibilityLabel("Start a call: talk hands-free")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape").font(.title3)
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
                LazyVStack(alignment: .leading, spacing: 16) {
                    if model.showWelcome { welcome }
                    ForEach(model.messages.filter { !$0.hidden }) { message in
                        MessageRow(message: message).id(message.id)
                    }
                    if model.isBusy {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text(model.status).foregroundStyle(.secondary)
                        }
                        .font(.title3)
                        .id("busy")
                    }
                }
                .padding(16)
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Hello! I'm Agatha.")
                .font(.title.bold())
            Text("Let's get to know each other. Tap Start and I will ask you a few short questions out loud, like a phone call. Just answer in your own words.")
                .font(.title3)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Talk / photo / type

    @ViewBuilder private var inputBar: some View {
        if model.showWelcome {
            VStack(spacing: 10) {
                StartButton()
                Text("Tap Start to begin")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(.bar)
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
        VStack(spacing: 10) {
            if model.isCallMode {
                HStack(spacing: 12) {
                    Text(callLabel)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(model.isRecording ? .red : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.updatesFrequently)
                    Button { model.endCall() } label: {
                        Label("End call", systemImage: "phone.down.fill")
                            .padding(.horizontal, 16)
                            .frame(minHeight: 52)
                    }
                    .buttonStyle(BigButtonStyle(color: .red))
                }
            } else if !model.status.isEmpty && !model.isBusy {
                Text(model.status)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(model.isRecording ? .red : .secondary)
                    .multilineTextAlignment(.center)
            }
            if !typing {
                TalkButton()
                if !model.isCallMode {
                    Text("Tap the button or shake your phone to talk")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                photoButton
            }
            typeField
        }
        .padding(16)
        .background(.bar)
    }

    private var photoButton: some View {
        Menu {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button { showCamera = true } label: { Label("Take a photo", systemImage: "camera") }
            }
            Button { showPhotoLibrary = true } label: { Label("Choose a photo", systemImage: "photo") }
        } label: {
            Label("Show me a photo", systemImage: "camera.fill")
                .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(BigButtonStyle(color: .indigo))
        .disabled(!model.canSend)
    }

    private var typeField: some View {
        HStack {
            TextField("Or type here", text: $typed, axis: .vertical)
                .font(.title3)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                .submitLabel(.send)
                .focused($typing)
                .onSubmit(sendTyped)
                .disabled(!model.canSend)
            if !typed.isEmpty {
                Button(action: sendTyped) {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 40))
                }
                .disabled(!model.canSend)
                .accessibilityLabel("Send")
            }
            if typing {
                Button("Done") { typing = false }
                    .font(.headline)
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
            VStack(alignment: .trailing, spacing: 8) {
                if let image = message.image {
                    Image(uiImage: image)
                        .resizable().scaledToFit()
                        .frame(maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                if !message.text.isEmpty {
                    Text(message.text)
                        .font(.title3)
                        .padding(14)
                        .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 18))
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                if !message.text.isEmpty {
                    HStack(alignment: .top, spacing: 10) {
                        Text(message.text)
                            .font(.title3)
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
                        Button { model.repeatAloud(message.text) } label: {
                            Image(systemName: "speaker.wave.2.fill").font(.title2)
                        }
                        .accessibilityLabel("Read it again")
                        .padding(.top, 12)
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Your AI skills").font(.headline)
                Spacer()
                Text("\(model.skills.count) of \(Skill.allCases.count)").font(.headline).foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                ForEach(Skill.allCases, id: \.self) { skill in
                    let done = model.skills.contains(skill)
                    VStack(spacing: 4) {
                        Image(systemName: done ? "checkmark.circle.fill" : skill.icon)
                            .font(.title2)
                            .foregroundStyle(done ? .green : .secondary)
                        Text(skill.label)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(done ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(skill.label), \(done ? "done" : "not yet")")
                }
            }
            if let learned = model.lastLearned {
                Text("New skill: \(learned.label)! 🎉")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
                    .task(id: learned) {
                        try? await Task.sleep(for: .seconds(4))
                        model.lastLearned = nil
                    }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

// MARK: - Shared button style

struct BigButtonStyle: ButtonStyle {
    var color: Color
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2.weight(.bold))
            .foregroundStyle(.white)
            .background(color.opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.4),
                        in: RoundedRectangle(cornerRadius: 18))
    }
}
