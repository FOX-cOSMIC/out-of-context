import SwiftUI
import UIKit

/// The phone camera (not available in the Simulator; there, use "Choose a photo").
struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onImage(image) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

/// Server address (the helper Mac, reached over Tailscale on a real phone), hands-free calls and deleting all data.
struct SettingsView: View {
    @EnvironmentObject private var model: ChatModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("serverURL") private var serverURL = ""
    @AppStorage("handsFree") private var handsFree = false
    @AppStorage("speechOnMac") private var speechOnMac = true
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("http://localhost:3000", text: $serverURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Helper computer")
                } footer: {
                    Text("Leave empty to use the team's helper computer (\(APIClient.defaultServer)).")
                }
                Section {
                    Toggle("Hands-free", isOn: $handsFree)
                } footer: {
                    Text("Agatha listens again by herself after speaking. Best in a quiet room.")
                }
                Section {
                    Toggle("Understand my voice on the helper computer", isOn: $speechOnMac)
                } footer: {
                    Text("Uses Whisper on the team's Mac (private, no speech company). Turn off to use the iPhone's own speech recognition.")
                }
                Section {
                    CalendarConnectRow(source: .google)
                    CalendarConnectRow(source: .apple)
                } header: {
                    Text("Calendars")
                } footer: {
                    Text("Demo: events come from Margaret's sample calendar.")
                }
                Section {
                    Button("Load Margaret's medication plan (demo)") {
                        model.loadDemoPlan()
                        dismiss()
                    }
                } footer: {
                    Text("For the demo, if scanning the plan does not work.")
                }
                Section {
                    Button("Delete all my data", role: .destructive) { confirmDelete = true }
                } footer: {
                    Text("Your plan and profile are saved only on this phone.")
                }
            }
            .navigationTitle("Settings")
            .toolbar { Button("Done") { dismiss() } }
            .confirmationDialog("Delete your plan, profile, ticks and skills?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    model.deleteAllData()
                    dismiss()
                }
            }
        }
    }
}

/// One simulated calendar connection (demo only: nothing leaves the phone, the events are Margaret's sample calendar).
private struct CalendarConnectRow: View {
    let source: DemoHistory.CalendarSource
    @AppStorage private var connected: Bool
    @State private var connecting = false

    init(source: DemoHistory.CalendarSource) {
        self.source = source
        _connected = AppStorage(wrappedValue: false, source.storageKey ?? "calendarApp")
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(source.label)
                if connecting {
                    Text("Connecting…").font(.footnote).foregroundStyle(.secondary)
                } else if connected {
                    Text("Connected · \(DemoHistory.shared.syncedCount(source)) events synced")
                        .font(.footnote).foregroundStyle(.green)
                }
            }
            Spacer()
            if connecting {
                ProgressView()
            } else if connected {
                Button("Disconnect", role: .destructive) { connected = false }
                    .buttonStyle(.borderless)
            } else {
                Button("Connect") {
                    connecting = true
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        connected = true
                        connecting = false
                    }
                }
                .buttonStyle(.borderless)
            }
        }
        .accessibilityElement(children: .contain)
    }
}
