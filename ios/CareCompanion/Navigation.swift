import SwiftUI

/// The five tabs of the bottom bar (from the design). Agatha's conversation lives on .talk.
enum AppTab: Hashable {
    case pills, scan, talk, notes, sos
}

/// Which tab is showing. Screens switch tabs through this, e.g. after a scan go back to .talk.
@MainActor
final class Navigator: ObservableObject {
    @Published var tab: AppTab = .talk
}
