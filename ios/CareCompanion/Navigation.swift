import SwiftUI

/// The five tabs of the bottom bar (from the design). Agatha's conversation lives on .talk.
enum AppTab: Hashable {
    case pills, scan, talk, notes, sos
}

/// Which tab is showing. Screens switch tabs through this, e.g. after a scan go back to .talk.
@MainActor
final class Navigator: ObservableObject {
    @Published var tab: AppTab = .talk
    /// Bumped by the Home button: the Talk tab then shows its big home screen again.
    @Published var homeTick = 0
    /// The typing field on the home screen (opened by the centre tab while on Home).
    @Published var showTyping = false
    /// A sheet the Pills tab opens by itself (demo launch argument -demoSheet); PillsView clears it.
    @Published var demoSheet: DemoSheet?

    /// Back to Agatha's home screen (does not start listening).
    func goHome() {
        tab = .talk
        homeTick += 1
    }
}
