import SwiftUI

@main
struct CareCompanionApp: App {
    @StateObject private var model = ChatModel()

    var body: some Scene {
        WindowGroup {
            ChatView()
                .environmentObject(model)
        }
    }
}
