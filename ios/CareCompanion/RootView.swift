import SwiftUI
import UIKit

/// The app shell: the current tab's screen with the design's bottom bar under it.
struct RootView: View {
    @EnvironmentObject private var model: ChatModel
    @EnvironmentObject private var navigator: Navigator

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch navigator.tab {
                case .talk: ChatView()
                case .pills: PillsView()
                case .scan: ScanView()
                case .notes: NotesView()
                case .sos: SOSView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // During the first "getting to know you" call there is nothing to see on the other tabs yet.
            if !model.showWelcome {
                BottomBar()
            }
        }
        .background(Theme.Colors.background.ignoresSafeArea())
    }
}

/// Pills, Scan, a raised round Talk button, Notes, SOS (as in tab-bar.html).
struct BottomBar: View {
    @EnvironmentObject private var model: ChatModel
    @EnvironmentObject private var navigator: Navigator

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            item(.pills, "Pills", "pills")
            item(.scan, "Scan", "camera")
            talkButton
            item(.notes, "Notes", "heart")
            item(.sos, "SOS", "phone", tint: Theme.Palette.sosText, idleBackground: Theme.Palette.sosSoft)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Theme.Palette.white, in: RoundedRectangle(cornerRadius: Theme.Metrics.tabBarCorner, style: .continuous))
        .shadow(color: Theme.Colors.shadow, radius: 16, y: 6)
        .padding(.horizontal, Theme.Metrics.screenPadding)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    private func item(_ tab: AppTab, _ label: String, _ icon: String,
                      tint: Color = Theme.Palette.inkMuted, idleBackground: Color = .clear) -> some View {
        let selected = navigator.tab == tab
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            navigator.tab = tab
        } label: {
            VStack(spacing: 2) {
                Image(systemName: selected ? "\(icon).fill" : icon).font(Theme.Fonts.tabIcon)
                Text(label).font(Theme.Fonts.tabLabel).lineLimit(1).minimumScaleFactor(0.7)
            }
            .foregroundStyle(selected && tab != .sos ? Theme.Palette.purpleDeep : tint)
            .frame(maxWidth: .infinity, minHeight: Theme.Metrics.tabItemHeight)
            .background(selected ? (tab == .sos ? Theme.Palette.sosSoft : Theme.Palette.lavender) : idleBackground,
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    /// Goes to the conversation and starts listening right away.
    private var talkButton: some View {
        let listening = model.isRecording || model.isStartingMic
        return Button {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            navigator.tab = .talk
            if model.isRecording {
                model.toggleRecording() // second tap: done talking
            } else if !model.isStartingMic && model.canSend {
                model.toggleRecording()
            }
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    Circle().fill(Theme.Palette.lavenderRing).frame(width: Theme.Metrics.tabTalkSize + 8, height: Theme.Metrics.tabTalkSize + 8)
                    Circle().fill(listening ? Theme.Colors.danger : Theme.Palette.purple)
                        .frame(width: Theme.Metrics.tabTalkSize, height: Theme.Metrics.tabTalkSize)
                        .shadow(color: Theme.Palette.purple.opacity(0.35), radius: 8, y: 4)
                    Image(systemName: listening ? "waveform" : "mic.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Theme.Colors.onColor)
                }
                .offset(y: -14)
                .padding(.bottom, -14)
                Text("Talk").font(Theme.Fonts.tabLabel).foregroundStyle(Theme.Palette.ink)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(listening ? "Agatha is listening" : "Talk to Agatha")
    }
}
