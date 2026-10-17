# Demo video script · Agatha (2:00 hard cap)

Judges watch this video first (Impact 40 · Working demo 20 · Technical 20 · Creativity 20).
So: real app on a real iPhone, one person's story, Agatha visibly doing the work, impact said out loud.

## Before you press record (2 minutes)

1. **Network + sound:** Tailscale ON on iPhone and Mac, server running on the Mac, iPhone volume up, quiet corner.
2. **No interruptions:** Do Not Disturb / Focus ON, other apps closed, battery not "low" (no yellow).
3. **Screen Recording with mic ON:** Control Center → long-press the record button → Microphone **On** → Start (3 s countdown).
4. **Fresh app:** Settings gear → **Delete all my data** (so we get the Start screen). Settings → **Hands-free OFF**.
5. **Props ready:** sample plan (`public/samples/medication-plan.png`) open full-screen on the Mac or printed; also saved in Photos as backup. **Never tap Call 112 on camera: it really dials.**

## Timed script

Short answers, speak slowly, pause half a second after tapping Agatha before you talk.
If Agatha is slow: **keep recording, stay silent, cut the wait in the edit.**

| Time | On screen | Lucas says / does | Agatha (expected) |
|---|---|---|---|
| 0:00-0:10 | Lucas or a teammate on camera, or Agatha home screen | (voice) "This is Margaret. She's 78, takes five medicines, has a drawer full of doctor's paperwork, and she has never used AI." | — |
| 0:10-0:15 | Start screen | (voice) "Meet Agatha." Tap **Start**. | — |
| 0:15-0:30 | Home, Agatha mascot, live words | (Agatha speaks) | "Hello, I'm Agatha... I help with your medicines, appointments and paperwork, just by talking or showing me a photo. What would you like me to call you?" |
| 0:30-0:45 | Words appear live as you speak | Tap Agatha: **"Margaret."** Tap again. Next: **"I have breakfast at eight."** (Answer 1-2 more, then cut in edit to the summary.) | Asks one question at a time, then: "Let me check I got that right... Did I get that right?" |
| 0:45-0:50 | Summary | Tap: **"Yes."** | Saves profile, suggests showing a photo of the medication plan. |
| 0:50-1:05 | Scan tab → camera on the plan | Tap **Scan**, photograph the plan. (voice) "She just shows it the paper." | **"Here is what I read"** card: Ramipril, Metformin, Simvastatin, ASS 100, Pantoprazole with doses per time of day. |
| 1:05-1:10 | Card | Tap **Yes, right**. | "Saved." |
| 1:10-1:20 | Home → schedule card | Tap Agatha: **"What do I take this evening?"** | Spoken answer + evening schedule card, "with your dinner at ...". |
| 1:20-1:30 | Ticks, then **Pills** tab with progress ring | Tap Agatha: **"I took my morning pills."** Then tap **Pills**. | "Well done, Margaret..." morning pills ticked; ring fills. |
| 1:30-1:42 | Home | Tap Agatha: **"Can I skip my Metformin?"** | "Please don't change anything on your own. Ask your doctor or pharmacist..." offers to note the question. |
| 1:42-1:48 | Quick flash: **Notes** (Good/Okay/Not well), **SOS** screen | Show only. **Do NOT tap Call 112.** (voice) "Notes for how she feels, SOS to call 112, her daughter or her doctor." | — |
| 1:48-2:00 | Agatha home screen (or team on camera) | (voice) "Medicines are why Margaret starts. AI skills are what she keeps: talk in your own words, show a photo, check the answer. Built in one day with Claude Code. Claude Opus 5.5 behind it, speech on the phone and on our own Mac, no speech company." | — |

## Exact phrases to say to Agatha

- "Margaret." / "I get up at seven." / "Breakfast at eight." / "Skip." (to jump a question)
- "Yes." / "Yes, that's right."
- "What do I take this evening?"
- "I took my morning pills."
- "Can I skip my Metformin?"

If she mishears: tap Agatha again and repeat, slower. Cut the miss in the edit.

## Voice-over lines (if live audio is messy: record the screen, then narrate over it)

1. "Margaret is 78. Five medicines, a drawer of paperwork, and she has never used AI."
2. "Agatha is a voice-first iPhone companion. One screen: tap her, talk, she answers out loud."
3. "First she gets to know Margaret, one question at a time, and checks she got it right."
4. "Margaret shows her the medication plan. Agatha reads it, and nothing is saved until Margaret checks it."
5. "Now she can just ask what to take, and tell Agatha when she's taken it."
6. "Agatha never gives medical advice. Change a medicine? Ask your doctor or pharmacist."
7. "Medicines are why they start. AI skills are what they keep. Built in one day with Claude Code; it runs on our own Mac."

## Editing notes

- **2:00 hard cap.** Cut onboarding hardest (keep greeting, one answer, the summary).
- Speed up waiting / "thinking" parts to 2x or cut them. Keep Agatha's voice at normal speed.
- Captions for key lines: the hook, "Here is what I read", "Yes, right", the safety answer, the closing line.
- No music over speech (quiet music only under the first 5 s, if at all).
- Export, upload (YouTube unlisted or Drive "anyone with link"), test the link in a private window, put it in the README and the form **before 15:45**.

## Plan B

- **Network / AI down:** run the iOS Simulator on the Mac and record with QuickTime (File → New Screen Recording), narrate after. In the Simulator use Scan → pick the plan from Photos.
- **Live transcription fails:** there is no typing field on the home screen. Tap Agatha again and speak again; if it still fails, check Tailscale and the server, then retry.
- **Camera scan is blurry:** pick `medication-plan.png` from Photos instead.
- **A reply is long or wrong:** keep going, cut it in the edit. Do not restart the whole take for one bad line.
- **Out of time at 15:35:** submit what you have. A rough working demo beats no video.

## Sources

- [AngelHack: 10 tips to rock your hackathon demo](https://angelhack.com/blog/10-tips-to-help-you-rock-your-next-hackathon-demo/) (time budget, narrate the hard part, don't describe what's visible)
- [hackathon.com: Creating the best demo video](https://tips.hackathon.com/article/creating-the-best-demo-video-for-a-hackathon-what-to-know) (start by showing the project, check the judging criteria)
- [AI Tinkerers: Video production guide for hackathons](https://aitinkerers.org/docs/public/video_production_guide.md?markdown=1) (real functionality not slides, realistic data, test the mic)
- [Gumlet: How to screen record on iPhone](https://www.gumlet.com/learn/how-to-screen-record-on-iphone-comprehensive-step-by-step-guide/) (long-press record, microphone on, silent videos usually = mic off)
