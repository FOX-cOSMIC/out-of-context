# Agatha demo video: text overlays

Times follow the `at` column of `video/script.md` (2:00 hard cap). Durations assume 30 fps in Remotion.
Each row names the SVG file and the `<g id>` to animate.

## How the SVGs are built for animation

- Every card, pill and line is its own `<g id>`; animate these with `transform` and `opacity`.
- Every word is a `<tspan id="…-wN" class="word">` inside its line. Use it for word-by-word reveals
  with `opacity` / `fill-opacity` only: browsers ignore `transform` on a `<tspan>`.
- Text is live text in Quicksand (headings, class `h`) and Atkinson Hyperlegible (body, classes `b`
  and `bb`). Each SVG also `@import`s the Google Fonts for standalone viewing. In Remotion, load both
  with `@remotion/google-fonts` and inline the SVG markup (an `<Img>` tag cannot reach web fonts).
- `lower-thirds.svg` stacks all bars for preview. Each bar group carries `transform="translate(96 y)"`:
  set it to `translate(96 880)` (bottom-left, inside title-safe) when you use it.
- `captions-style.svg` has a `spec-notes` group that is documentation only: hide it.

## Overlay table

| Scene | Time | On-screen text | Asset · group | Animation | Duration |
|---|---|---|---|---|---|
| 00-title | 0:00–0:02 (optional cold open) | **Agatha** · A voice companion that helps older adults with their medicines — and with AI. | `title-open.svg` · `title`, `subtitle-line1`, `subtitle-line2`, `eyebrow` | `title` scale 0.92→1 + fade (12 f); subtitle words fade in word by word (2 f per word); "and with AI." last, in purple | 2 s (cut if the hook needs the time) |
| 01-hook | 0:02–0:09 | Margaret, 78 | `hook-cards.svg` · `card-margaret` | slide up 40 px + fade (10 f, ease-out) on "seventy-eight" | 7 s |
| 01-hook | 0:04–0:09 | 5 medicines a day | `hook-cards.svg` · `card-medicines` | same slide-up, staggered on "Five medicines" | 5 s |
| 01-hook | 0:07–0:09 | Never used AI | `hook-cards.svg` · `card-never-ai` | same slide-up, then a small scale pop 1→1.04→1 (orange card) | 2 s; all three slide down out at 0:09 |
| 02-call | 0:13–0:18 | Agatha calls at pill time | `lower-thirds.svg` · `lt-02-call-pill-time` | bar wipes in from left (scaleX 0→1 from left edge, 10 f), then typewriter on the text | 5 s |
| 02-call | 0:18–0:23 | AI calls her — no app to open | `lower-thirds.svg` · `lt-02-call-no-app` | crossfade from the previous bar; word-by-word | 5 s |
| 02-call | 0:26–0:32 | Only “already taken” counts | `lower-thirds.svg` · `lt-02-call-taken-counts` | slide up + fade; words `-w2`/`-w3` ("already taken") fade in last | 6 s |
| 03-scan | 0:41–0:49 | Scan → she spots what’s new | `lower-thirds.svg` · `lt-03-scan-whats-new` | wipe in from left; typewriter, short hold on the arrow | 8 s |
| 03-scan | 0:50–0:55 | AI skill: check what AI read | `lower-thirds.svg` · `lt-03-scan-check-ai` | slide up; "AI skill:" first, the rest word by word | 5 s |
| 04-safety | 1:00–1:07 | No medical advice — ever | `lower-thirds.svg` · `lt-04-safety-no-advice` | wipe in; "ever" (`-w5`) arrives 10 f late | 7 s |
| 04-safety | 1:08–1:13 | Questions go to her doctor | `lower-thirds.svg` · `lt-04-safety-doctor` | crossfade from the previous bar; word-by-word | 5 s |
| 05-memory | 1:17–1:25 | How did I do this week? 95% | `lower-thirds.svg` · `lt-05-memory-week` | question typewriter in sync with Margaret; "95%" (`-w7`) appears when Agatha says it (option: count 0→95 in Remotion) | 8 s |
| 06-family | 1:26–1:36 | No answer after 30 min → Anna is told | `lower-thirds.svg` · `lt-06-family-anna` | wipe in; word-by-word timed to "Later doesn't count … half an hour" | 10 s |
| 06-family | 1:33–1:39 | SIMULATED | `lower-thirds.svg` · `lt-06-family-simulated-chip` | scale 0→1 pop (8 f) beside Anna's message footage | 6 s, as long as her message is on screen |
| 06→07 | 1:39–1:43 | How it works: Claude Sonnet 5.5 with tools · speech + voice on our own Mac · data stays on the phone · Tailscale | `tech-card.svg` · `tech-heading`, `tile-claude`, `tile-speech`, `tile-data`, `tile-tailscale`, `tech-footnote` | heading fade; tiles slide up staggered 6 f apart; footnote last | 4 s (no voice under it) |
| 07-close | 1:43–1:49 | 3 AI skills Margaret learns · Talk in your own words · Show a photo · Check the answer | `skills-row.svg` · `skills-heading-plate` + `skills-heading`, `skill-talk`, `skill-photo`, `skill-check` | heading drops in; each tile scales 0.9→1 + fades exactly on its spoken skill | 6 s |
| 07-close | 1:50–2:00 | Medicines are why they start. AI skills are what they keep. · Agatha · Team Out of Context · Claude Impact Lab Berlin 2026 | `end-card.svg` · `mascot`, `pitch-line1`, `pitch-line2`, `credits` | mascot bounces in (spring); pitch lines word by word in sync with the narrator; `credits` fades up at 1:55 and holds | 10 s |
| all | every spoken line | the spoken words, max 2 lines | `captions-style.svg` · `caption-agatha` / `caption-margaret` style | pill fades in (4 f) at line start, out (4 f) at line end; speaker label colour: Agatha lavender `#CDB8FF`, Margaret orange `#FF7A3D` | length of each voice line |
