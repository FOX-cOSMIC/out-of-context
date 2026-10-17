import SwiftUI
import UserNotifications

@main
struct CareCompanionApp: App {
    @StateObject private var model = ChatModel()
    @StateObject private var navigator = Navigator()
    private let calls = CallScheduler.shared

    init() {
        // Set early so tapping an "Agatha is calling" notification that launches the app is not lost.
        UNUserNotificationCenter.current().delegate = CallScheduler.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .environmentObject(navigator)
                .environmentObject(calls)
                .task {
                    DemoLaunch.run(model: model, navigator: navigator) // demo-video launch arguments
                    calls.attach(model: model)
                    // Pill reminder call answered: Agatha speaks first, then the call runs hands-free.
                    calls.onAccepted = { info in
                        model.startMedicationCall(slot: info.slot, medicines: info.medicines, attempt: info.attempt)
                    }
                    // Pills ticked in the call checklist: Agatha hears it and asks about the rest.
                    calls.onPillsTicked = { slot, ticked, remaining in
                        model.reportPillsTicked(slot: slot, ticked: ticked, remaining: remaining)
                    }
                    // "I've taken them" said out loud: the call screen confirms and hangs up.
                    model.onIntakeConfirmed = { slot in calls.confirmIntake(for: slot) }
                }
                // Valentina's palette is light-only.
                .preferredColorScheme(.light)
        }
    }
}
