# Agatha demo video (Remotion)

The 2-minute demo video, built in code with [Remotion](https://www.remotion.dev) (React).
Timeline and assets per scene: [TIMELINE.md](TIMELINE.md).

## Render

```bash
cd video/remotion
npm install          # once
npm run render       # -> out/agatha-demo.mp4 (h264, 1920x1080, 30 fps)
npm run studio       # preview and scrub in the browser
```

`npm run render` first runs `npm run sync-assets`, which copies `video/voices/lines/*.wav`,
`video/graphics/**` and `video/recordings/*.mp4` into `public/` and writes `src/generated/manifest.json`
(which assets exist, recording lengths, the phone-frame screen rect). Anything missing (or a recording that
is still being written and cannot be read) is shown as a labelled placeholder, so the video always renders.

## After the recordings arrive

1. Put the files in `video/recordings/` with the planned names: `01-home.mp4`, `02-call-ringing.mp4`,
   `03-call-conversation.mp4`, `04-scan.mp4`, `05-safety-question.mp4`, `06-week-summary.mp4`,
   `07-pills-history.mp4`, `08-calendar.mp4`, `09-family-call.mp4` (`10-sos.mp4` is not used).
2. Run `npm run render`. Each recording plays muted inside the phone frame from its in point; if it is
   shorter than its slot it freezes on its last frame. A file that is still being written is skipped
   (placeholder) until the next sync.
3. In/out points live on each clip in the scene files (`src/scenes/*.tsx`, the `clips={[...]}` of `<Phone>`):
   `trimBefore: sec(2.5)` / `trimAfter: sec(24.5)` are seconds in the source file (current values follow
   `video/recordings/RECORDINGS.md`). After a re-record, check those points still fit.

## Change things

- Timing: `src/timeline.ts` (scene lengths, when each voice line starts). A line that would run past its
  scene stops the render with an error. Then `node scripts/timeline-table.mjs` to refresh TIMELINE.md.
- Voice text or audio: edit `video/script.md`, re-run `video/voices/generate.py`, then render (captions and
  lengths come from `video/voices/lines.json`).
- Look: colours and fonts in `src/theme.ts` (same palette as the app; Quicksand + Atkinson Hyperlegible).

Scenes: `src/scenes/` (Hook, Call, Scan, Safety, Week, Family, Tech, Close). Shared pieces: `src/components/`
(Phone, captions + voice audio + speaking bounce, animated text, placeholders).
