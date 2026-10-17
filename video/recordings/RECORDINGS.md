# App screen recordings (iOS Simulator)

Recorded 2026-10-17 on the iPhone 17 simulator (0ABA0E8B), app built from commit `240a76b`, with the
launch arguments from `docs/demo-launch-args.md` and the real helper server (Claude + local voice) on
`localhost:3000`. All files: H.264, 1206x2622 (portrait, native resolution), **video only, no audio**
(`simctl recordVideo` does not capture sound; Agatha's real voice was not captured, see Issues).

Every file starts with ~2 s of the iOS home screen before the app launches, so always trim the head.
`simctl` writes frames only when the screen changes: a file ends at the last change, so a static
final screen may be shorter than the wait. Hold the last frame in the edit if you need more.

The status bar is overridden to a clean look (full battery, full bars); the clock is set per scene to
match the story.

| File | Duration | Clock | What it shows | Use (in-out) |
|---|---|---|---|---|
| `01-home.mp4` | 10.0 s | 09:00 | Clean home screen: Agatha, "What's on your mind, Margaret?", "Tap Agatha to talk", tab bar. Static. | 2.5-10.0 s |
| `02-call-ringing.mp4` | 15.1 s | 18:00 | Home (2.4 s), then at 5.8 s the incoming call: "Phone call / Agatha / Medication reminder / 18:00 · Evening pills · Metformin, Simvastatin", Decline / Accept. Still ringing at the end. | 5.0-15.1 s (or 2.5 s to include the home screen) |
| `03-call-conversation.mp4` | 40.4 s | 18:00 | Ringing 5.8 s, auto-accepted 8.6 s ("Evening pills · 18:00, Waiting for your confirmation" card with Metformin 500 mg and Simvastatin 20 mg checkboxes). At ~10 s Agatha's opening line: "Hello Margaret, it's time for your evening pills: one Metformin and one Simvastatin, with your dinner at 6. Have you taken them yet?" (status "Agatha is speaking…"), then "Listening…" from ~20.6 s. | **5.5-24.5 s** (ring, pick up, opening line, Listening…). Do not use after 24.5 s. |
| `04-scan.mp4` | 47.9 s | 12:00 | Home, "Thinking…" (~6-10.7 s), then Agatha: "Amlodipine is new: one 5 mg tablet in the morning, for blood pressure. Please check the card against your box, then tap Yes or No." with the "Here is what I read · Amlodipine 5 mg · for blood pressure" card. Auto "Yes, that's right." (~19 s), "Thinking…", then at 26 s: "Saved. Amlodipine is now on your plan, one 5 mg tablet in the morning. Well done, Margaret!" | 2.5-35.0 s (cut the Thinking gaps as needed) |
| `05-safety-question.mp4` | 30.3 s | 14:30 | "Can I skip my Metformin today?" appears ~4 s, "Thinking…", answer at 6.5 s: "I can't advise on skipping medicines, Margaret. Please don't change anything on your own; ask Dr Hoffmann or your pharmacist today. Shall I note it for Dr Hoffmann?" | 2.0-20.0 s |
| `06-week-summary.mp4` | 29.6 s | 14:30 | "How did I do with my pills this week?", "Thinking…", answer at 6.6 s: "Very well, Margaret: 95% this week, and your mornings were perfect. Only two evening Metformin doses slipped, Monday and Thursday. Shall I show today's pills?" | 1.5-20.0 s |
| `07-pills-history.mp4` | 10.6 s | 09:00 | Pills tab ("My pills today 0/6") with the "My week & month" sheet sliding up (1.3-2.8 s): 95% ring, "40 of 42 taken", text about the missed evening Metformin, "The last 7 days" row (Mon 12 and Thu 15 orange). | 1.3-10.6 s |
| `08-calendar.mp4` | 11.1 s | 09:00 | "My calendar" sheet: October 2026 month grid (17 highlighted, dot on 29), "Today, Saturday 17 October · Nothing planned", "Coming up · Thursday 29 October · 09:30" (doctor). | 2.5-11.1 s |
| `09-family-call.mp4` | 12.0 s | 18:30 | "Agatha couldn't reach you": "Calling Anna (your daughter) · Ringing…" from 2.5 s, "Connected · Anna has been told you haven't confirmed your evening pills." (~8 s), then "Anna has been informed ✓" with OK (~11 s). Footer "Demo: no real call is made." | 2.5-12.0 s |
| `10-sos.mp4` | 3.8 s | 09:00 | "Need help?" screen: Call 112, Call Anna, Call Dr. Hoffmann, Send a help message. Appears at 2.5 s; file ends at 3.8 s because the screen is static. | 2.5-3.8 s, then freeze the last frame |

## Issues

- **Call scenes show the evening pills, not the morning ones.** `-testCall` rings for the next slot
  still open by the real clock (it was ~15:30), so the call is "Evening pills · Metformin,
  Simvastatin", not the script's morning line (Ramipril, Metformin, Pantoprazole, aspirin). The status
  bar clock was set to 18:00 to match. Getting the morning version needs the Mac's clock before
  the morning slot, or a launch argument that picks the slot.
- **03-call-conversation: room sound got in after 24.5 s.** The Simulator listens through the Mac's
  real microphone; it transcribed nearby speech ("Let me show you. So basically, you kind of just
  like"), Agatha answered "Sorry, Margaret, I didn't quite catch that…", and the call then ticked
  both pills off and ended by itself (~36-38 s, back to home with "Thank you for ticking off your
  Metformin…"). The first take had the same problem earlier (a transcript arrived before the call),
  so it was replaced. Use only 5.5-24.5 s, or record in a quiet room.
- **04-scan: the "Here is what I read" card is cut off by the tab bar**: only its title and
  "Amlodipine 5 mg · for blood pressure" are visible, the Yes / No buttons are off-screen (the
  auto-tap still works). The scanned photo itself is not shown on screen.
- **06-week-summary: the last line of Agatha's answer** ("show today's pills?") is partly hidden
  behind the tab bar.
- **10-sos: "Call Dr. Dr Hoffmann"**: the doctor's name is shown with a doubled title (app bug, the
  demo data or label adds "Dr." twice).
- **01-home:** no greeting bubble appears after `-demoReset` (it turned up inside the call in 03 as
  "Hello again, Margaret! Ask me what to take today, or show me a new letter.").
- **No audio.** Agatha's real voice played through the Mac speakers; no loopback device was active
  as the output, so it was not captured. Use the generated voice lines in `video/voices/lines/`.
