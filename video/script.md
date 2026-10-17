# Agatha demo video: voice script

Team Out of Context · Concept A "A day with Margaret" · hard cap 2:00.
Source timeline: `demo-plan/index.html` (Timeline section) and `DEMO-IDEAS.md` (Concept A).

All spoken audio is generated locally with Kokoro-82M (`tts/server.py`), one voice per person.
The audio files are in `video/voices/lines/`, the listening page is `video/voices/index.html`, and
`video/voices/generate.py` regenerates every line from the table below plus the cast map in that script.

## Roles

| Role | Who | Voice brief |
|---|---|---|
| NARRATOR | Explains the idea, links the beats | Calm, warm, British |
| MARGARET | Margaret Weber, 78, five medicines, never used AI | Gentle, a little slower |
| ANNA | Her daughter, 40s, lives 300 km away | Warm, a bit busy |
| AGATHA | The app's voice | Must stay Kokoro `bf_emma`, exactly as in the app |

## Lines

The generator reads this table. Columns: `#` (file number), `scene`, `role`, `text` (exactly what is
spoken; numbers and titles are written out so the voice says them right), `at` (where it sits in
the 2:00 cut). Keep the column order; edit text freely and re-run the generator.

| # | scene | role | text | at |
|---|---|---|---|---|
| 01 | 01-hook | NARRATOR | Margaret is seventy-eight. Five medicines, a drawer full of paperwork, and she has never used AI. | 0:01 |
| 02 | 01-hook | NARRATOR | Today, AI calls her. | 0:09 |
| 03 | 02-call | AGATHA | Good morning, Margaret. It's time for your morning pills: Ramipril, Metformin, Pantoprazole and your aspirin. Have you taken them yet? | 0:13 |
| 04 | 02-call | MARGARET | Yes, I took them. | 0:23 |
| 05 | 02-call | AGATHA | Well done, all your morning pills are ticked off. | 0:26 |
| 06 | 03-scan | NARRATOR | At noon, a new box arrives from the pharmacy. She just shows it to Agatha. | 0:33 |
| 07 | 03-scan | AGATHA | Amlodipine is new and isn't on your plan yet. Everything else matches. Please check the card. | 0:41 |
| 08 | 03-scan | NARRATOR | She checks what AI read. That's her first AI lesson. | 0:50 |
| 09 | 04-safety | MARGARET | Can I skip my Metformin today? | 0:56 |
| 10 | 04-safety | AGATHA | Please don't change anything on your own. Ask Doctor Hoffmann or your pharmacist. Shall I note the question? | 1:00 |
| 11 | 04-safety | MARGARET | Yes, please. | 1:08 |
| 12 | 04-safety | AGATHA | Done. It's in your notes for Doctor Hoffmann. | 1:10 |
| 13 | 05-memory | MARGARET | How did I do this week? | 1:14 |
| 14 | 05-memory | AGATHA | Well done, you took 95 percent of your doses this week. Your mornings were perfect. | 1:17 |
| 15 | 06-family | NARRATOR | And if she doesn't confirm? Later doesn't count, so Agatha tries again. After half an hour, Anna is told. | 1:26 |
| 16 | 06-family | ANNA | Thanks, Agatha. I'll call Mum. | 1:37 |
| 17 | 07-close | NARRATOR | Talk in your own words. Show a photo. Check the answer. | 1:43 |
| 18 | 07-close | NARRATOR | Medicines are why they start. AI skills are what they keep. | 1:50 |

## Notes for the edit

- Measured durations per line are on `video/voices/index.html`; total speech is about 75-85 s, leaving
  room for taps, the alarm and app footage.
- 02-call: on screen the alarm notification, "Agatha is calling", then Slide to confirm while line 04
  plays. The real app reads the medicine names it has in the plan; "ASS 100" is spoken as "your
  aspirin" so the voice doesn't read the German abbreviation.
- 03-scan: line 07 is how the app phrases a scan compared with the saved plan. If a recorded take has
  Agatha's own audio, use that and drop line 07.
- 06-family: Anna's message on screen is labelled "simulated".
- Spare beat (cut first if long): the eye clinic letter. Not voiced yet.
