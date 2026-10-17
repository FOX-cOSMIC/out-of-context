import SwiftUI

@main
struct CareCompanionApp: App {
    @StateObject private var model = ChatModel()
    @StateObject private var navigator = Navigator()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .environmentObject(navigator)
                // Valentina's palette is light-only.
                .preferredColorScheme(.light)
        }
    }
}
