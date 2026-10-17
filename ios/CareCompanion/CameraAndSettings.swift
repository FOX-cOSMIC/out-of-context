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

/// Server address (for a real phone on the same wifi) and deleting all data.
struct SettingsView: View {
    @EnvironmentObject private var model: ChatModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("serverURL") private var serverURL = ""
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
