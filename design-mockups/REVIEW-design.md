# Agatha design review: A vs B vs C

Reviewed: A-calm-minimal.png, B-warm-companion.png, C-max-accessibility.png, plus the shipped home screen (sim-talk2.png). Scores are 1-10.

## Scores

| Criterion | A Calm minimal | B Warm companion | C Max accessibility |
|---|---|---|---|
| Clarity of the main action | 8 | 6 | 10 |
| Visual hierarchy | 9 | 7 | 8 |
| Consistency across the 5 screens | 9 | 6 | 9 |
| Brand fit (purple, lavender, mascot, fonts) | 8 | 9 | 7 |
| Warmth vs. seriousness (health app) | 8 | 7 | 7 |
| Shows "You said" and Agatha's answer | 8 | 8 | 10 |
| SwiftUI feasibility, under 1 h on current app | 9 | 5 | 8 |
| **Total (of 70)** | **59** | **48** | **59** |

### Notes per direction

- **A, calm minimal.** Closest to what ships today: same "What's on your mind, Margaret?" home, the talk pill and keyboard button side by side, and the tab bar unchanged. Strengths: an answer screen with a "You said" bubble, then the answer in big type with "Speaking, tap to hear again", then a card of actions; an SOS screen with named contacts. Weaknesses: the talk pill is smaller than the current app's button and has no second line of help text, the keyboard button has no word under it, and the dark "Done talking" button is the only dark button in the whole set.
- **B, warm companion.** Has the most personality: the mascot itself is the talk button and changes face for each state (ready, listening, speaking), and colour shows time of day. But "Tap me and ask" is a small pill on top of a picture, which is easy to miss for someone new to smartphones. The raised centre tab changes its label (Home, Listening, Agatha) from screen to screen, which breaks consistency, and the orange used for listening is close to the "now" warning colour. It also needs new mascot artwork for each state and a different tab bar. This direction would take far more than an hour to build.
- **C, max accessibility.** Clearest of the three: one dominant button per screen, every icon has a word, a coloured banner names the state ("Agatha is listening. Tap DONE when you have finished", "Agatha is speaking out loud"), and the "YOU SAID" / "I HEAR YOU SAYING" labels are excellent. Downsides: all-caps "TAP TO TALK", the dark green DONE and "Yes, I took it" buttons, and the 3px outlines on every card make it feel institutional and move away from the purple brand. Brand fit and warmth lose points for that.

## Recommendation

**A's layout and calm look, plus C's labels and state banners, plus B's mascot states used lightly.**

Keep the shipped home screen and A's structure (the current app is already about 80% of A). Add C's habits: name the state in words on every screen, label every control with a word, and give "Yes, I took it" one full-width main button. From B, take only the idea of the mascot changing face to show its state, as a small avatar swap on the screen. Do not make the mascot the button, and do not change the tab bar. Stay in sentence case and use brand purple for main actions. Use C's green only for "taken" checkmarks, not for buttons.

One thing to fix across all three: the shipped mascot (dark visor face with orange glasses) is not the one in the mockups (white face, round glasses). Pick one before shipping.

## Top 5 changes to the current app, in priority order

1. Add a state banner above the conversation that names what is happening in words ("I'm listening. Tap Done when you've finished" / "Agatha is speaking. Tap to hear again"), in lavender, with orange for listening.
2. Show what the user said as a labelled "You said" bubble (A/C style) above Agatha's answer, which appears in large Atkinson type (27pt or more) next to a small Agatha avatar and a "Say it again" button.
3. Fill the empty middle of the home screen with one "Next pills" card (time, names, chevron to Pills), as in A and C, so the screen answers "what now?" before she even talks.
4. While listening, turn the "Tap to talk" button into a full-width "Done" button in brand purple with a separate "Cancel" text button, and show the words live as she speaks under the heading "I hear you saying".
5. Put action cards under Agatha's answers ("This evening, 6:00 pm", each medicine with a 56pt-tall "Take" button) and use one full-width "Yes, I took it" button for the pill due now on the Pills tab.
