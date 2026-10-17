# Agatha: demo review and video ideas

Reviewer pass, 17 Oct 2026, ~14:50. Based on README, DEMO-SCRIPT, prompts/chat.md, abilities doc, design reviews, scan test results, the Swift sources and a simulator screenshot of the current home screen.

---

## 1. Review: what a judge sees

### Strengths (say these out loud, they score)

- **A real audience with a real daily pain.** 70+, five medicines, paper plans, family worry. Impact (40 pts) is easy to believe if we show Margaret's life, not features.
- **Agatha does real work with Claude, not just chat:** vision reads a plan or box, 9 tools turn into cards and actions (schedule, mark taken, propose meds and appointments, save note, keep document, open screen). The scan test (6 PASS, 1 safe PARTIAL, no invented values) is evidence: put it in the README.
- **Safety you can watch:** "Can I skip my Metformin?" goes to the doctor or pharmacist. A Yes/No check after every scan ("check what AI tells you"). Missed doses never mean "double up". Off-topic questions get steered back.
- **Privacy story is unusual for a hackathon:** speech (Whisper) and voice (Kokoro) run on our own Mac, server only on 127.0.0.1 plus Tailscale, plan and notes stay on the phone.
- **Agatha calls you** (the pill call with retries and a family alert) flips the usual app model: an older person does not have to remember to open anything. That is the most memorable thing for Creativity.
- **Accessible design that holds up:** big type, Atkinson Hyperlegible, a word under every tab icon, a mascot with a name.

### 5 biggest risks / weak spots

1. **The "AI education" theme is invisible in the app right now.** `SkillsBar` exists in `ChatView.swift` but is used nowhere, so the "AI skills bar" the README promises isn't on screen. The theme is *AI education for everyone*; a judge might decide it's "a pill app with a chatbot". The 2-minute video has to say the skills out loud (talk, show, check, ask again), and ideally show them in the app.
2. **The README and DEMO-SCRIPT describe a different app.** They still describe the getting-to-know-you call, Call mode, the skills bar, "Take" buttons, "six tools" and "Show me a photo → Choose a photo". The DEMO-SCRIPT closing line says "Claude Opus 5.5", but `server.js` uses `claude-sonnet-5-5`. Judges read the README right after the video, so any mismatch costs Technical and trust points.
3. **The network chain can fail live.** iPhone → Tailscale → Mac server → Claude API, plus Whisper and Kokoro on the Mac. Venue wifi or a sleeping Mac breaks talking *and* the voice. Errors are spoken raw (`error.localizedDescription` in `ChatModel.swift`), so Margaret's Agatha might say "The request timed out." Replies also take 3-8 s, which feels like dead air on stage.
4. **The pill call is new and only partly wired.** I found only the `-testCall` launch argument as a trigger in `CallScheduler.swift`; the Settings test button and the family alert weren't visible yet. If it isn't stable by recording time, the strongest moment becomes the riskiest. Real retries are 10 minutes apart (30 s in test mode), so on stage it must start from a test trigger.
5. **Live-demo confusion points:**
   - **Call 112 dials straight away.** `SOSView.call()` opens `tel://112` with no confirm. One mis-tap on stage makes a real emergency call. The usability review ranked this fix as number 1.
   - **After an answer, the mascot scrolls away** (see screenshot: a big Morning card, and "Tap Agatha to talk again" with no Agatha visible).
   - The centre tab reads "Type" on Home, which looks like the main action, and Notes still has a heart icon.
   - The date shows as a small grey "17 Oct".
   - Calendar and history are simulated (Margaret's demo data). If you don't say so, a judge who asks will think we hid it.

### Quick wins (each 15 min or less)

| # | Win | Why |
|---|---|---|
| 1 | Add a confirm step before 112 ("Call 112 now?" Yes/No); in the demo, only ever tap "Call Anna" | Removes a real-world hazard on stage; an easy safety answer in Q&A |
| 2 | Put `SkillsBar()` back in `ChatView` (top, compact), or show "New skill: Show a photo!" toasts | Makes the theme visible in every shot |
| 3 | Fix the README top half: current features, Sonnet 5.5, 9 tools, the pill call, the "real vs simulated" list, a link to `samples/test/RESULTS.md` | Judges read it second; it should match the video |
| 4 | Swap raw error text for a kind line ("I couldn't reach my helper computer. Please try again in a moment.") | No technical words spoken on camera |
| 5 | Keep the mascot pinned (shrink it, don't scroll it away), or change the hint to "Tap the purple button to talk" | Removes the "where is Agatha?" moment |
| 6 | Pre-load the demo state: Settings → "Load Margaret's medication plan (demo)", the history week filled in, calendar connected | No setup on camera; the history answers work |
| 7 | Notes icon heart → `note.text`; date → "Saturday, 17 October" | Polish judges notice |

---

## 2. Demo video concepts (2:00 each)

Exact phrases are kept short. Speak slowly, and pause half a second after tapping Agatha.

### Concept A: "A day with Margaret" (RECOMMENDED)

**Hook:** "Margaret is 78 and has never used AI. Today, AI calls *her*."

| Time | Beat | On screen / said |
|---|---|---|
| 0:00-0:10 | Hook | Margaret's hands, a kitchen table, the pill boxes and a paper plan. VO: "Margaret is 78. Five medicines, a drawer of paperwork, and she has never used AI." |
| 0:10-0:30 | **8:00, Agatha calls** | The phone rings with "Agatha is calling · Morning pills". Accept. Agatha: "Good morning Margaret, it's time for your morning pills with breakfast..." Say: **"I took them."** The ring fills on Pills. |
| 0:30-0:55 | **Noon, a new box from the pharmacy** | Tap Scan, photograph the Amlodipine box. "Here is what I read" card. Agatha: "**Amlodipine is new; everything else matches your plan.** Please check the card." Tap **Yes**. VO: "She checks what AI read. That's the first AI lesson." |
| 0:55-1:10 | Safety | Say: **"Can I skip my Metformin today?"** Agatha: don't change anything on your own, ask Dr Hoffmann or the pharmacist, shall I note the question? Say: **"Yes, please."** The note is saved. |
| 1:10-1:25 | A letter from the eye clinic | Scan the letter. Agatha: Tuesday 3 Nov, 10:15, bring glasses, don't drive, maybe Anna can come. Yes, saved. |
| 1:25-1:40 | **Evening reflection** | Say: **"How did I do this week?"** Agatha: "Your mornings were perfect..." Cut to Pills → My week. |
| 1:40-1:50 | Missed call → family | Quick cut: the call is not answered three times, "Agatha let Anna know". Anna's phone shows the message (it can be a staged second phone or a simulated screen; label it). |
| 1:50-2:00 | Close | VO: "Talk in your own words. Show a photo. Check the answer. Medicines are why Margaret starts; AI skills are what she keeps. Claude Sonnet 5.5, voice on our own Mac." |

- **Wow moment:** Agatha ringing like a phone call, then "Amlodipine is new".
- **Risks:** the call feature isn't stable, the scan reply skips the "new" sentence, the run goes over 2:00.
- **Plan B:** record the call from the Simulator with `-testCall` (QuickTime), or drop the call beat and open on the Pills tab. Do 2-3 scan takes and keep the one that says "new". Cut the eye letter first if the run is long.

### Concept B: "The drawer of paperwork" (before / after)

**Hook:** "Every older person has this drawer. We taught it to talk."

| Time | Beat |
|---|---|
| 0:00-0:15 | **Before:** a messy drawer with plans, boxes, a bank letter and a sticky note from Anna. VO on the confusion: "Which plan is current? What's this letter?" |
| 0:15-0:40 | Scan the updated plan → Agatha: "**Simvastatin has been replaced by Atorvastatin, and Vitamin D is new.**" Yes. |
| 0:40-0:55 | Scan the bank letter → a plain explanation and "The bank will never ask for your PIN by phone." Say **"Yes, keep it."** It goes to My papers. |
| 0:55-1:10 | Scan Anna's handwritten note → "This matches your plan." |
| 1:10-1:25 | Scan the blurry plan → "Too blurry to read safely, please take it again." VO: "When she isn't sure, she says so." |
| 1:25-1:45 | **After:** an empty, tidy drawer. Notes → My papers, Pills → today. Say: **"When is my next appointment?"** |
| 1:45-2:00 | Close on the AI skills: show, check, ask. |

- **Wow moment:** the plan change spotted in one sentence, and the honest "too blurry" answer.
- **Risks:** it's scan-heavy, so voice and the daily habit get little screen time; it looks like OCR unless you narrate it.
- **Plan B:** pick the photos from Photos instead of the camera; all samples are in `public/samples/test/`.

### Concept C: "Anna's phone" (the daughter's perspective)

**Hook:** "Anna lives 300 km away. She used to call Mum every evening just to ask about pills."

| Time | Beat |
|---|---|
| 0:00-0:15 | Anna on a train, worried, texting "Did you take your pills, Mum?" |
| 0:15-0:45 | Cut to Margaret: Agatha's morning call, "I took them", the ring fills. |
| 0:45-1:05 | Margaret scans the new box, Agatha says it's new, Margaret checks and taps Yes. |
| 1:05-1:20 | Margaret: **"I feel a bit dizzy today."** Agatha: kind, offers to note it for Dr Hoffmann, and says the SOS screen is there. Say **"Yes."** It's noted. |
| 1:20-1:40 | Evening: three missed calls, and Anna gets "Agatha couldn't reach Mum for her evening pills." Anna calls Mum. |
| 1:40-2:00 | VO: "Margaret stays independent; Anna stops worrying. And Margaret has learned to use AI." |

- **Wow moment:** the missed calls reaching Anna.
- **Risks:** it depends most on the newest, least-tested feature; the family alert is simulated and needs a second phone or a mock; it needs two actors; it shows the least AI skill.
- **Plan B:** turn Anna into a VO bookend only, and the middle becomes Concept A.

### Recommendation: Concept A

It covers every judging line in one believable day: Impact (a daily habit plus family), Working demo (voice, vision, tools on a real phone), Technical (comparing with the saved plan, history answers, local voice), and Creativity (Agatha calls you). Every beat has a fallback, and the AI-skills lesson is said in the scan beat and the close. Borrow B's "too blurry" shot (5 s) if there is room, and C's Anna message as the 10-second family beat.

---

## 3. Finals: 6-minute live demo

Setup: the phone mirrored (QuickTime / AirPlay) or a document camera; the Mac server, Whisper and Kokoro already warm (send one test request 2 min before); the demo plan and history pre-loaded; the call armed with a test trigger; a backup video cued on a laptop.

| Time | Who / what |
|---|---|
| 0:00-0:45 | **Story.** Margaret, 78: five medicines, paper plans, a worried daughter, never used AI. "We built the AI she would actually use." |
| 0:45-1:45 | **Agatha calls.** Trigger the test call; the phone rings on screen. Accept, say "I took them", the ring fills. Point out: she didn't open an app. |
| 1:45-2:45 | **Show, check.** Scan the Amlodipine box live → "Amlodipine is new" → tap Yes. Say: "This is the first AI lesson: always check what AI read." |
| 2:45-3:30 | **Safety.** "Can I skip my Metformin?" → refers her to the doctor and offers to note the question. "Yes" → Notes, "For Dr Hoffmann". |
| 3:30-4:15 | **Memory.** "How did I do this week?" → a warm summary, then the Pills → My week view. "When is my next appointment?" → the calendar answer. |
| 4:15-4:45 | **Family.** Show the missed-call screen and the alert to Anna (say it's simulated). Show SOS, but tap only "Call Anna", never 112. |
| 4:45-5:30 | **Under the hood** (one slide or the README diagram): Sonnet 5.5 with 9 tools and vision, strict schemas, Whisper and Kokoro on our Mac, the phone keeps the data, the scan test results. |
| 5:30-6:00 | **Close.** "Medicines are why they start. AI skills are what they keep." Next steps in one line. |

Live rules: one person drives, one narrates. If a reply takes more than 8 s, the narrator talks through what Claude is doing. If the network dies, switch to the backup video at the same beat and keep narrating.

### 5 likely judge questions

1. **"Isn't this giving medical advice? What if it misreads a dose?"**
   Agatha explains and organises; she never says keep, skip, stop or combine. Those questions go to the doctor or pharmacist, and she offers to note them. Nothing from a photo is saved until the user taps Yes. When a photo is too blurry she asks for a new one instead of guessing. In our 7 scan tests nothing was invented. Emergencies → 112.
2. **"Where does Margaret's data go?"**
   The plan, notes and papers stay on the iPhone, and there is a "Delete all my data" button. Speech-to-text (Whisper) and the voice (Kokoro) run on our own Mac, not a speech company. The server listens only on localhost, reached through a private Tailscale network. Claude sees the conversation, the newest photo and the plan, so it can answer. Production would need a hosted backend with a data agreement (EU region, no training on the data).
3. **"Why would a 78-year-old use this when she won't use ChatGPT?"**
   She doesn't have to learn an app: Agatha calls her, she just talks, or holds up the paper. It starts with a job she already has every day (her pills), not "try AI". Big type, a word on every button, and a patient voice that uses her name and meal times. The family is the way in: Anna installs it, and Margaret keeps using it.
4. **"What's real and what's simulated?"**
   *Real:* Claude with vision and tools, the scanning and plan comparison, the schedule and ticks, notes and papers, the history and calendar answers (from demo data), local Whisper and Kokoro, running on a real iPhone. *Simulated:* the "call" is an in-app call screen with local notifications (no phone network); the Google/Apple calendar connection is demo data; the family alert is a simulated message. (Fix this list before the finals to match the build.)
5. **"Business model / what next?"**
   Who pays: families (a monthly subscription, bought by Anna), plus pharmacies and care services (a white-label for their customers). Germany's Medikationsplan has a barcode on paper plans, so we could read it exactly. Next steps: real reminder notifications and alarms, sharing with family only with consent, more languages (German first), and a pilot with a pharmacy or a senior centre.

---

## Screenshot

`/tmp/claude-scratch/demo-ideas/current.png` (scratch, delete with `rm -rf /tmp/claude-scratch/demo-ideas`): the home screen after an answer, with the mascot scrolled away and the "Type" centre tab.
