# Agatha · by Team Out of Context

**A voice-first iPhone companion that helps older adults understand their medicines and appointments, and on the way teaches them to use AI: talk to it, show it a photo, check its answer, ask follow-ups.**

> Medicines are why they start. AI skills are what they keep.

**Our idea: to help older people use and learn AI, we simplify.** One face, one tap, plain words. No menus to learn, just talk. And the AI comes to them: Agatha calls when it's time for their pills.

Built in one day at the Claude Impact Lab Berlin (theme: *AI education for everyone*). Agenda and rules: [event repo](https://github.com/Claude-Community-Berlin/claude-impact-lab-berlin-2026-10-17).

**Demo video:** [video/agatha-demo-final.mp4](https://github.com/FOX-cOSMIC/out-of-context/blob/main/video/agatha-demo-final.mp4) (1:36, plays in the browser)

---

## Who it's for

- **Audience:** older adults (roughly 70+) who take several medicines a day and get confusing paperwork from doctors and clinics, plus the family members who help them from afar.
- **Their problem with AI today:** most have never used AI for anything useful. They hear about it, but nobody has shown them a reason or a safe way to start.
- **What Agatha lets them do:** talk to Agatha in their own words, show her a photo of a medication plan or a letter, check what she read, and get reminded (by a friendly "call") when it is time for their pills.

## The problem

Many older people take several medicines a day, often from different doctors, and keep track of them on paper. Mixing up doses or forgetting what a tablet is for is common and risky, and the family worries. Letters from clinics are written in dense, official language. Reminder apps exist, but they expect people to type in drug names and schedules themselves, which is exactly the hard part.

Agatha flips that: you just talk, or hold up the paper. And because every step is a small, real use of AI (speak in your own words, show a photo, check the answer, ask again), people learn the skills that make AI useful for everything else too.

## Meet Margaret (our demo person)

The demo app starts as **Margaret Weber, 78**: five medicines (Ramipril, Metformin, Simvastatin, ASS 100, Pantoprazole), breakfast at 8, a little hard of hearing, new to smartphones. Her daughter **Anna** helps from 300 km away; her GP is **Dr Hoffmann**. Margaret, her plan, her appointments and her last 30 days are all fictional.

## What it does

The app has five big, labelled tabs: **Pills, Scan, Home, Notes, SOS**.

- **Tap Agatha and talk.** On Home, tap the big Agatha mascot and speak. Your words appear live while you talk; Agatha answers out loud in a warm British voice, in one or two short sentences (never more than 25 words). Typing works too.
- **Agatha calls you at pill time.** At each pill time an iPhone-style call screen rings with a gentle ringtone: *"Hello Margaret, it's time for your evening pills: one Metformin and one Simvastatin. Have you taken them yet?"* She only counts a clear "I've taken them"; "later" is not a yes, so she kindly asks again. You can also tick each pill on the call screen. No answer? She tries again (3 tries, 10 minutes apart), and after that Anna is told (simulated in the demo). The person no longer has to remember to open an app.
- **Show a photo (Scan).** Photograph a medication plan, a medicine box or an appointment letter. Agatha shows a **"Here is what I read"** card and compares it with the saved plan ("Amlodipine is new; everything else matches"). Nothing is saved until you tap **Yes**. Blurry photo? She asks for a new one instead of guessing.
- **Any other letter.** Show her a bill, a form or an official letter, and she explains in plain words what it is and what you need to do. If you want, she keeps it in **Notes → My papers**.
- **My pills today.** The Pills tab shows today's pills by time of day with a progress ring and a big **Yes, I took it** button. Or just say "I took my morning pills" and Agatha ticks them off. "Did I take my pills?" is answered from the ticks, never from guesswork.
- **Notes for the doctor.** "Please write down that I felt dizzy" or "note my question for Dr Hoffmann" saves a note, so the questions are ready for the next visit.
- **How did I do this week?** Agatha knows the last 30 days and the calendar: "Your mornings were perfect this week." She is warm and never scolds. (History and calendar are demo data; the Google/Apple calendar connection is simulated.)
- **SOS.** One screen with big buttons: call 112, call Anna, call the doctor. Saying "Agatha, I need help" opens it.
- **Agatha opens screens for you.** "Show me my pills" or "I need help" switches to the right tab, so nobody has to hunt for buttons.
- **Teaching AI along the way.** Now and then, after helping, Agatha adds one short tip for a skill not yet practised ("By the way, you can show me any letter, not just medicine papers"), and praises people when they try something new.

### Real vs simulated in the demo

| Real | Simulated / demo data |
|---|---|
| Talking to Claude, photo reading, all cards and ticks | Margaret's profile, 30-day history and calendar |
| Speech-to-text and Agatha's voice | The Google/Apple calendar connection |
| The pill call screen, ringtone, retries and confirmation | The "Anna has been told" family call (no real call is made) |
| Notes and kept papers on the phone | All sample documents (fictional) |

## Safety and privacy by design

- **Explains and organises, never advises.** Agatha never tells anyone to keep, skip, stop or combine a medicine. Questions about changes, side effects, symptoms or interactions get "please ask your doctor or pharmacist", and she offers to write the question down. A missed dose never becomes "take it now" or "double up".
- **Emergencies go to 112.** Chest pain, trouble breathing, a fall or sudden confusion: she tells them to call 112 now or get help nearby.
- **A human check after every photo.** AI can misread, so the user confirms each card. That is also the lesson: always check what AI tells you.
- **Agatha only does what she says.** Each ability is a tool call; she never claims to have saved or opened something she didn't, and she cannot call, message or share anything herself.
- **Stays on topic.** News, recipes, trivia: one kind sentence, then back to medicines and appointments.
- **Plan, profile and notes stay on the phone** (`UserDefaults` and the app's Documents folder). *Settings → Delete all my data* erases everything.
- **Speech stays on the phone or on our own Mac.** Speech recognition runs on the iPhone, or on Whisper on our own Mac (*Settings → Understand my voice on the helper computer*). Agatha's voice (Kokoro) also runs on our Mac. No speech company is involved.
- **What Claude sees.** Each chat request sends the conversation, the newest photo, the saved plan, the profile, today's ticks and recent notes, so Claude can answer. Older photos are replaced by a placeholder.
- **Private network only.** The helper server listens only on the Mac itself (`127.0.0.1`). A real iPhone reaches it through Tailscale, a private network between our own devices.
- **Demo documents are fictional.** All names, medicines, addresses and letters in `samples/` are made up.

## How Claude is used

Claude is the heart of the product, not just the tool that wrote it.

- **Model:** `claude-sonnet-5-5` (Claude Sonnet 5.5, fast enough for voice; override with `CLAUDE_MODEL` in `.env`) via the Anthropic API, called from `server.js` with the official `@anthropic-ai/sdk`. The API key stays on the server; the phone never sees it.
- **One conversation, with tools.** The app sends everything to `POST /api/chat`. Claude answers in short spoken sentences and can call ten tools:

  | Tool | What happens in the app |
  |---|---|
  | `show_schedule` | Schedule card (all day, or morning / midday / evening / night) |
  | `show_appointments` | Appointments card |
  | `propose_medications` | "Here is what I read" card with Yes / No; replaces the plan or adds one box |
  | `propose_appointments` | "Here is what I read" card for appointment letters |
  | `mark_taken` | Ticks off the named medicines for that time of day |
  | `confirm_intake` | Confirms the pills during a reminder call and ends the call |
  | `open_screen` | Switches to Pills, Scan, Notes, SOS or Home |
  | `save_note` | Saves a note, a feeling or questions for the doctor |
  | `save_document` | Keeps the photographed letter in My papers (only after the user says yes) |
  | `save_profile` | Saves the profile on the phone |

  The tools change nothing on the server: each becomes a card or an action that the app shows or applies. Details: [docs/agatha-abilities.md](docs/agatha-abilities.md).
- **Vision** reads the photo of the plan, box or letter in the same conversation.
- **Strict tool schemas** (`strict: true`, every field required, no extra fields), so the app always gets data it can display.
- **The prompt** lives in one place: [`prompts/chat.md`](prompts/chat.md) (personality, length limit, tools, pill calls, teaching AI skills, safety). The profile, saved plan, today's ticks, history, calendar, notes and practised skills are added below it on every request.
- **Tested on real documents.** We ran 7 fictional test scans (new box, changed plan, handwritten family note, blurry photo, eye clinic letter, bank letter) against real Claude: **6 pass, 1 safe partial, 0 invented values.** See [samples/test/RESULTS.md](samples/test/RESULTS.md).
- **Refusals** are handled gently: if Claude refuses, the user hears "Sorry, I cannot help with that one. Please ask your doctor or pharmacist."

## Architecture

```
 iPhone app (SwiftUI, ios/)
   talk / photo / taps          cards, actions, spoken replies
          │                                   ▲
          ▼        Tailscale (private)        │
 Node server on our Mac (server.js, 127.0.0.1:3000)
   ├─ POST /api/chat        → Claude API (claude-sonnet-5-5, tools + vision)
   ├─ POST /api/transcribe  → ffmpeg + Whisper (whisper.cpp, large-v3-turbo), local
   └─ POST /api/speak       → Kokoro TTS service (tts/server.py, 127.0.0.1:3002), local
                              falls back to the macOS `say` voice if it is not running
```

## How to run it

New to the project? [SETUP.md](SETUP.md) is a step-by-step checklist for setting up a Mac (Xcode, tools, model, key).

### 1. The helper server (on a Mac)

Needs Node.js 22 or newer.

```bash
cp .env.example .env    # paste your ANTHROPIC_API_KEY into .env
npm install
npm start               # listens on http://localhost:3000
```

`npm run dev` restarts the server automatically when you change a file. `GET /api/health` shows whether the API key is set and which voice settings are in use.

**Speech-to-text** (needed for talking to Agatha):

```bash
brew install whisper-cpp ffmpeg
```

and put the Whisper model at `~/.local/share/whisper/ggml-large-v3-turbo.bin` (or point `WHISPER_MODEL` in `.env` to another `ggml` model file). The language is English by default (`WHISPER_LANG`).

**Better voice (optional).** Without it, Agatha uses the built-in macOS voice (`SAY_VOICE`, default Samantha). For a warm, natural voice, run the local [Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M) model via [mlx-audio](https://github.com/Blaizzy/mlx-audio) (Apple Silicon Mac, needs [`uv`](https://docs.astral.sh/uv/)) in a second terminal:

```bash
npm run tts             # first start downloads the model (~340 MB) into ~/.cache/huggingface
```

It listens only on `127.0.0.1:3002`; the server uses it automatically and falls back to the macOS voice when it is not running. Change the voice with `KOKORO_VOICE` (default `bf_emma`, British; try `af_heart` for American).

### 2. The app in the iPhone Simulator

Needs Xcode 26 with an iOS Simulator.

```bash
brew install xcodegen
cd ios && xcodegen generate     # optional: the generated project is committed too
open CareCompanion.xcodeproj
```

Pick an iPhone simulator and press Run. The Simulator talks to the server at `http://localhost:3000`, and uses the Mac's microphone for talking.

To try the photo flow, drag `public/samples/medication-plan.png` and `public/samples/appointment-letter.png` (more in `public/samples/test/`) onto the Simulator window (they land in Photos), then open the **Scan** tab.

To see the pill reminder call, open *Settings* (gear icon) → **Test pill call in 10 seconds**. In test mode the retries are 30 seconds apart, so the whole flow (3 tries, then the family call) takes about 90 seconds.

### 3. The app on a real iPhone

1. In Xcode, select the *CareCompanion* target → *Signing & Capabilities* and set your team (a free Apple ID works).
2. On the iPhone, enable *Settings → Privacy & Security → Developer Mode*, connect it, and run on the device.
3. Put the Mac and the iPhone in the same [Tailscale](https://tailscale.com) network.
4. The server only listens on `127.0.0.1`. On our demo Mac, Tailscale runs in userspace-networking mode (`tailscaled --tun=userspace-networking`), which hands incoming tailnet connections to local programs, so the phone reaches `http://<Mac's Tailscale IP>:3000` with no extra step (tested from the iPhone). With the regular Tailscale app, share the port into your tailnet instead, e.g. `tailscale serve --bg --tcp 3000 tcp://127.0.0.1:3000`. Either way only devices in your tailnet can reach it.
5. On real devices the app uses our Mac's Tailscale address by default (`APIClient.defaultServer` in `ios/CareCompanion/APIClient.swift`). For your own Mac, enter `http://<your Mac's Tailscale IP>:3000` under *Settings → Helper computer* in the app.

Please don't start the server with `HOST=0.0.0.0` on a public or shared wifi: that would open it to everyone on the network.

## Project layout (who owns what)

| Path | What it is | Owner |
|---|---|---|
| `server.js` | Small Node server: talks to Claude, runs the tools, keeps the API key secret | Gabriela |
| `prompts/chat.md` | Agatha's instructions: personality, pill calls, AI-skills teaching, safety | Gabriela |
| `ios/` | The SwiftUI iPhone app (`project.yml` for XcodeGen, sources in `ios/CareCompanion/`) | Ahmad (code), Camila (design, `Theme.swift`) |
| `voice.js`, `tts/` | Local speech-to-text (Whisper) and voice (Kokoro, macOS fallback) | Lucas |
| `samples/` | Fictional sample documents (HTML source), rendered to `public/samples/*.png` with headless Chrome | Lucas |
| `README.md` | This file, the pitch story | Valentina |
| `video/`, `demo-plan/`, `DEMO-SCRIPT.md` | Demo video script, voice lines (Kokoro) and plan | Lucas, Valentina |

To re-render a sample after editing its HTML (use `--window-size=900,560` for `appointment-letter`):

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --hide-scrollbars \
  --window-size=1060,465 --screenshot="$PWD/public/samples/medication-plan.png" "file://$PWD/samples/medication-plan.html"
```

## Team rule: pull often, push often

- Start every task with `git pull --rebase`.
- After every small working step: commit, `git pull --rebase`, `git push`. Don't sit on changes for more than ~15 minutes.
- Claude Code follows this automatically (it's in `CLAUDE.md`). If you work on github.com directly, refresh before editing.

## Team

| Name | Role / background |
|---|---|
| Gabriela | Builder |
| Ahmad | Builder |
| Camila | Product design |
| Valentina | Founder |
| Lucas | Domain expert (videography) |

## Credits

- [Anthropic API](https://docs.claude.com) and the official [`@anthropic-ai/sdk`](https://github.com/anthropics/anthropic-sdk-typescript) (MIT)
- [whisper.cpp](https://github.com/ggml-org/whisper.cpp) (MIT) with OpenAI's Whisper large-v3-turbo model (MIT)
- [Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M) (Apache 2.0), run through [mlx-audio](https://github.com/Blaizzy/mlx-audio) (MIT)
- [misaki](https://github.com/hexgrad/misaki) (MIT), the G2P (text-to-phoneme) library used by Kokoro
- [FFmpeg](https://ffmpeg.org) for audio conversion
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (MIT)
- Apple SwiftUI and AVFoundation
- All sample documents, names and addresses are fictional.
- Fonts: [Quicksand](https://github.com/google/fonts/tree/main/ofl/quicksand) (Andrew Paglinawan and the Quicksand Project Authors) and [Atkinson Hyperlegible](https://github.com/google/fonts/tree/main/ofl/atkinsonhyperlegible) (© 2020 Braille Institute of America), both SIL Open Font License 1.1.
- Visual design and Agatha mascot: Valentina (`Medication Voice Assistant.html`).
