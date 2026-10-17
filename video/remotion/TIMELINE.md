# Agatha demo video: timeline

1920x1080, 30 fps, **118.0 s** (cap 120 s). Source of truth: `src/timeline.ts` (scene lengths and the
second each voice line starts inside its scene); line lengths come from `video/voices/lines.json`.
Regenerate the table below with `node scripts/timeline-table.mjs` after changing timings.

| scene | what | start | end | length |
|---|---|---|---|---|
| hook | Hook | 0:00.0 | 0:12.5 | 12.5 s |
|  | line 01 NARRATOR | 0:00.8 | 0:08.3 | 7.55 s |
|  | line 02 NARRATOR | 0:09.0 | 0:11.7 | 2.65 s |
| call | 09:00 call | 0:12.5 | 0:32.0 | 19.5 s |
|  | line 03 AGATHA | 0:15.1 | 0:23.3 | 8.22 s |
|  | line 04 MARGARET | 0:24.1 | 0:26.4 | 2.27 s |
|  | line 05 AGATHA | 0:27.0 | 0:30.4 | 3.38 s |
| scan | Scan | 0:32.0 | 0:53.0 | 21.0 s |
|  | line 06 NARRATOR | 0:32.6 | 0:38.4 | 5.83 s |
|  | line 07 AGATHA | 0:40.2 | 0:46.5 | 6.28 s |
|  | line 08 NARRATOR | 0:47.4 | 0:52.0 | 4.6 s |
| safety | Safety | 0:53.0 | 1:11.5 | 18.5 s |
|  | line 09 MARGARET | 0:53.7 | 0:56.7 | 3 s |
|  | line 10 AGATHA | 0:57.4 | 1:04.3 | 6.9 s |
|  | line 11 MARGARET | 1:05.0 | 1:07.0 | 2 s |
|  | line 12 AGATHA | 1:07.6 | 1:10.8 | 3.17 s |
| week | Week | 1:11.5 | 1:24.5 | 13.0 s |
|  | line 13 MARGARET | 1:12.2 | 1:14.9 | 2.65 s |
|  | line 14 AGATHA | 1:15.5 | 1:21.2 | 5.7 s |
| family | Family | 1:24.5 | 1:39.0 | 14.5 s |
|  | line 15 NARRATOR | 1:25.2 | 1:33.0 | 7.8 s |
|  | line 16 ANNA | 1:34.5 | 1:36.8 | 2.35 s |
| tech | How it works | 1:39.0 | 1:42.5 | 3.5 s |
| close | Close | 1:42.5 | 1:58.0 | 15.5 s |
|  | line 17 NARRATOR | 1:43.2 | 1:47.8 | 4.6 s |
|  | line 18 NARRATOR | 1:48.8 | 1:53.7 | 4.9 s |

Total: 118.0 s

## Assets per scene

Recording in/out points follow `video/recordings/RECORDINGS.md` (every clip opens with ~2 s of the iOS home screen, trimmed). A clip shorter than its slot holds its last frame.

Every scene: voice WAVs `voices/lines/NN-*.wav` at the times above, a caption pill per line, fade in/out (10 frames).
Phone: `graphics/scenes/phone-frame.svg` (screen rect x=200 y=160 1206x2622 r=186), recordings muted inside it.

| scene | vector graphics | recordings on the phone | animated text |
|---|---|---|---|
| Hook | scenes/bg-kitchen.svg (slow push-in), characters/margaret-table.svg, scenes/drawer-paperwork.svg | 01-home.mp4 from 2.5 s (phone slides in at line 02) | lower third "Meet Margaret Weber"; chips "Margaret, 78 · 5 medicines · never used AI" (slide-up); "Today, AI calls her." (typewriter) |
| 09:00 call | scenes/bg-soft-gradient.svg, characters/margaret-phone-call.svg, characters/agatha-{speaking,listening,happy}.svg, scenes/clock-9am.svg, scenes/incoming-call-badge.svg | 02-call-ringing.mp4 from 5.0 s (until line 03), then 03-call-conversation.mp4 8.0-24.5 s (pick-up, Agatha speaking, Listening) | lower third "09:00 Agatha calls"; "AI calls her. / She doesn't have to open an app." (word-by-word); chip "Morning pills ticked off" |
| Scan | bg-soft-gradient, characters/margaret-table.svg, scenes/medicine-box-amlodipine.svg (drops in, flies to the phone), Agatha | 04-scan.mp4 2.5-35 s (the read card lands as line 07 starts) | lower third "12:00 A new box from the pharmacy"; chips "AI skill: show a photo", "AI skill: check the answer"; "Here is what I read" card; "Her first AI lesson." (typewriter) |
| Safety | bg-soft-gradient, characters/margaret-thinking.svg, Agatha | 05-safety-question.mp4 3.0-20 s | lower third "Safety"; "Never medical advice. / Questions go to her doctor." (word-by-word); note card "Note for Dr Hoffmann" |
| Week | bg-soft-gradient (evening tint), Agatha, scenes/calendar-week.svg | 06-week-summary.mp4 1.5-20 s, 07-pills-history.mp4 from 1.3 s (scene 8.0 s), 08-calendar.mp4 from 2.5 s (scene 10.5 s) | lower third "Evening: How did I do this week?"; 95 % ring counting up; chip "Mornings: perfect"; "Answers from her own history and calendar" |
| Family | bg-soft-gradient, characters/anna-phone.svg, scenes/family-alert.svg | 09-family-call.mp4 from 2.5 s, freezes on "Anna has been informed" | lower third "Later doesn't count"; retry track 09:00 → +10 → +20 → +30 min "Anna is told"; message card labelled "simulated" |
| How it works | titles/tech-card.svg (no voice) | none | whole card springs in |
| Close | bg-soft-gradient, Agatha, titles/end-card.svg (from the end of line 18) | 01-home.mp4 from 2.5 s | three skill cards on each spoken skill; pitch line word-by-word; footer "Claude Sonnet 5.5 · speech and voice on our own Mac" |

Known mismatch: the call recordings show the 18:00 evening reminder (Metformin, Simvastatin) while voice line 03 says morning pills; the phone text is small on screen, the story framing stays morning (as the voice says). Re-record the call in the morning slot to fix it fully.

Not used: recordings/10-sos.mp4 (SOS is not in the voice script), titles/title-open.svg (no room before line 01),
titles/hook-cards.svg, lower-thirds.svg, skills-row.svg, captions-style.svg (the same designs are drawn natively in
React so they can animate and avoid the caption area).
