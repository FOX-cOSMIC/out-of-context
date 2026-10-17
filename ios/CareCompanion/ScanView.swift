import PhotosUI
import SwiftUI

/// "Show me your medicine": take or choose a photo; Agatha reads it in the conversation.
struct ScanView: View {
    @EnvironmentObject var model: ChatModel
    @EnvironmentObject var navigator: Navigator
    @State private var showCamera = false
    @State private var photoItem: PhotosPickerItem?

    private var hasCamera: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    var body: some View {
        TabScreen {
            ScreenHeader(title: "Show me your medicine")

            ScanFrame()

            Text("Hold your medication plan, pill box or letter inside the frame so I can read it.")
                .font(Theme.Typeface.body(20))
                .foregroundStyle(Theme.Palette.inkMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 18) {
                if hasCamera {
                    Button { showCamera = true } label: {
                        VStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 96, height: 96)
                                .background(Theme.Palette.purple, in: Circle())
                                .padding(8)
                                .background(Theme.Palette.lavender, in: Circle())
                            Text("Take photo")
                                .font(Theme.Typeface.heading(22))
                                .foregroundStyle(Theme.Palette.ink)
                        }
                    }
                    .buttonStyle(PressableCardStyle())
                    .accessibilityLabel("Take photo")
                }

                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Choose a photo", systemImage: "photo.on.rectangle")
                        .font(Theme.Typeface.heading(21))
                        .foregroundStyle(Theme.Palette.purpleDeep)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(Theme.Palette.lavender, in: Capsule())
                        .overlay(Capsule().stroke(Theme.Palette.lavenderBorder, lineWidth: 1.5))
                }
                .buttonStyle(PressableCardStyle())

                if !model.canSend {
                    Text("Agatha is busy. One moment, please.")
                        .font(Theme.Typeface.body(18))
                        .foregroundStyle(Theme.Palette.inkSoft)
                }
            }
            .frame(maxWidth: .infinity)
            .disabled(!model.canSend)
            .opacity(model.canSend ? 1 : 0.5)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in send(image) }
                .ignoresSafeArea()
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    send(image)
                }
                photoItem = nil
            }
        }
    }

    /// Go to the conversation; Agatha reads the photo there and shows the confirm card.
    private func send(_ image: UIImage) {
        guard model.canSend else { return }
        navigator.tab = .talk
        Task { await model.send(text: "", image: image) }
    }
}

/// Dark frame with white corner brackets and a pill-bottle drawing (the design's "camera view").
private struct ScanFrame: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28).fill(Color(hex: 0x2A2140))
            CornerBrackets()
                .stroke(.white, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                .padding(44)
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: 0xEDEBF0))
                    .frame(width: 56, height: 26)
                    .padding(.bottom, 4)
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.Palette.orangeDark)
                    .frame(width: 80, height: 112)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: 0xFFF3EC))
                            .frame(width: 62, height: 46)
                    )
            }
            .accessibilityHidden(true)
        }
        .aspectRatio(1.05, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }
}

private struct CornerBrackets: Shape {
    func path(in rect: CGRect) -> Path {
        let l: CGFloat = 46
        var p = Path()
        // top-left
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + l))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + l, y: rect.minY))
        // top-right
        p.move(to: CGPoint(x: rect.maxX - l, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + l))
        // bottom-right
        p.move(to: CGPoint(x: rect.maxX, y: rect.maxY - l))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - l, y: rect.maxY))
        // bottom-left
        p.move(to: CGPoint(x: rect.minX + l, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - l))
        return p
    }
}

#Preview {
    ScanView()
        .environmentObject(ChatModel())
        .environmentObject(Navigator())
}
