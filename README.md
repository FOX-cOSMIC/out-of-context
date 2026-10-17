# Agatha · by Team Out of Context

**A voice-first iPhone companion that helps older adults understand their medicines and appointments, and on the way teaches them to use AI: talk to it, show it a photo, check its answer, ask follow-ups.**

> Medicines are why they start. AI skills are what they keep.

Built in one day at the Claude Impact Lab Berlin (theme: *AI education for everyone*). Agenda and rules: [event repo](https://github.com/Claude-Community-Berlin/claude-impact-lab-berlin-2026-10-17).

**Demo video:** <link added at submission>

---

## Who it's for

- **Audience:** older adults (roughly 70+) who take several medicines a day and get confusing paperwork from doctors and clinics, plus the family members who help them.
- **Their problem with AI today:** most have never used AI for anything useful. They hear about it, but nobody has shown them a reason or a safe way to start.
- **What Agatha lets them do:** talk to Agatha like a person, show her a photo of a medication plan or a letter, check what she read, and get a simple daily schedule they can ask questions about.

## The problem

Many older people take several medicines a day, often from different doctors, and keep track of them on paper. Mixing up doses or forgetting what a tablet is for is common and risky, and the family worries. Letters from clinics are written in dense, official language. Reminder apps exist, but they expect people to type in drug names and schedules themselves, which is exactly the hard part.

Agatha flips that: you just talk, or hold up the paper. And because every step is a small, real use of AI (speak in your own words, show a photo, check the answer, ask again), people learn the skills that make AI useful for everything else too.

## What it does

- **A getting-to-know-you call.** On first launch, one big *Start* button. Agatha introduces herself and asks one short question at a time: what to call you, when you get up and eat, whether hearing, eyesight or phones are hard, who in the family helps, who your GP is. She reads the summary back and saves it only after you agree. From then on she uses your name, your real meal times ("with your breakfast at 8") and your helper's name.
- **Call mode, turn by turn.** Tap *Call* and talk: Agatha answers out loud, then says it is your turn and you tap the big button to answer, until *End call*. She stops listening by herself when you have finished. Busy room? Nothing is picked up until you tap. In a quiet room, *Settings → Hands-free* lets her listen again by herself after speaking.
- **See what Agatha hears.** While you talk, your words appear live in the conversation, so you can see she understood you. When you stop, they become your message.
- **Easy to talk to.** A huge, pulsing talk button, or simply shake the phone to talk. Replies are spoken in a warm voice, slower for people who said hearing or eyesight is hard. Typing works too.
- **Show me a photo.** Photograph a medication plan, a medicine box or an appointment letter. Agatha shows a **"Here is what I read"** card with every medicine (dose per time of day) or appointment, plus anything she could not read clearly. Nothing is saved until you tap **Yes, right**.
- **My medicines today.** Ask "What do I take this evening?" and a schedule card appears, with a big **Take** button for each medicine (it turns into a green **Taken**). Or just say "I took my morning pills" and Agatha ticks them off.
- **Any other letter.** Show her a bill, a form or any official letter, and she explains in plain words what it is and what you need to do.
- **An AI-skills bar.** Across the top: *Talk in your own words*, *Show a photo*, *Check the answer*, *Ask a follow-up*. Each one lights up the first time you do it ("New skill!"), and Agatha now and then suggests the next one. People learn how to use AI by using it for something they care about.

## Safety and privacy by design

- **Explains and organises, never advises.** Agatha never tells anyone to keep, skip, stop or combine a medicine. Questions about changes, side effects, symptoms or interactions get "please ask your doctor or pharmacist", and she offers to write the question down for the next visit.
- **Emergencies go to 112.** Chest pain, trouble breathing, a fall or sudden confusion: she tells them to call 112 now or get help nearby.
- **A human check after every photo.** AI can misread, so the user confirms each card. That is also the lesson: always check what AI tells you.
- **Plan and profile stay on the phone.** They are stored only on the iPhone (`UserDefaults`). *Settings → Delete all my data* erases plan, profile, ticks and skills.
- **Speech stays on the phone or on our own Mac.** Your words are written down live by the iPhone's own speech recognition, on the phone itself where the iPhone supports it (otherwise by Apple's speech recognition service). If that is switched off or unavailable, the recording goes to Whisper on our own Mac instead. Agatha's voice (Kokoro) also runs on our Mac.
- **What Claude sees.** Each chat request sends the conversation, the newest photo, the saved plan and the profile to Claude, so it can answer. Older photos are replaced by a placeholder.
- **Private network only.** The helper server listens only on the Mac itself (`127.0.0.1`). A real iPhone reaches it through Tailscale, a private network between our own devices; it is never exposed on public wifi.
- **Demo documents are fictional.** All names, medicines, addresses and letters in `samples/` are made up.

## How Claude is used

Claude is the heart of the product, not just the tool that wrote it.

- **Model:** `claude-sonnet-5-5` (Claude Sonnet 5.5, fast for voice; override with `CLAUDE_MODEL` in `.env`) via the Anthropic API, called from `server.js` with the official `@anthropic-ai/sdk`. The API key stays on the server; the phone never sees it.
- **One conversation, with tools.** The app sends everything to `POST /api/chat`. Claude answers in short spoken sentences and can call six tools:

  | Tool | What happens in the app |
  |---|---|
  | `show_schedule` | Schedule card (all day, or morning / midday / evening / night) with Taken buttons |
  | `show_appointments` | Appointments card |
  | `propose_medications` | "Here is what I read" card with Yes / No; replaces the plan or adds one box |
  | `propose_appointments` | "Here is what I read" card for appointment letters |
  | `mark_taken` | Ticks off the named medicines for that time of day |
  | `save_profile` | Saves the getting-to-know-you profile on the phone |

  The tools change nothing on the server: each becomes a card or an action that the app shows or applies.
- **Vision** reads the photo of the plan, box or letter in the same conversation.
- **Structured, strict tool schemas** (`strict: true`, every field required, no extra fields), so the app always gets data it can display.
- **The prompt** lives in one place: `prompts/chat.md` (personality, the getting-to-know-you call, teaching AI skills, safety rules). The profile, saved plan, today's ticks and practised skills are added below it on every request.
- **Refusals** are handled gently: the server uses the server-side refusal fallback, and if Claude still refuses, the user hears "Sorry, I cannot help with that one. Please ask your doctor or pharmacist."

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

To try the photo flow, drag `public/samples/medication-plan.png` and `public/samples/appointment-letter.png` onto the Simulator window (they land in Photos), then tap **Show me a photo → Choose a photo**.

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
| `prompts/chat.md` | Agatha's instructions: personality, first call, AI-skills teaching, safety | Gabriela |
| `ios/` | The SwiftUI iPhone app (`project.yml` for XcodeGen, sources in `ios/CareCompanion/`) | Ahmad (code), Camila (design, `Theme.swift`) |
| `voice.js`, `tts/` | Local speech-to-text (Whisper) and voice (Kokoro, macOS fallback) | Lucas |
| `samples/` | Fictional sample documents (HTML source), rendered to `public/samples/*.png` with headless Chrome | Lucas |
| `README.md` | This file, the pitch story | Valentina |

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
