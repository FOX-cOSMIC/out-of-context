> 👋 **Starter for Claude Impact Lab teams.** Fill in each section below as you build and delete this note.
>
> 📅 **Agenda, rules, deadline and judging** are in the event repo: **[claude-impact-lab-berlin-2026-10-17](https://github.com/Claude-Community-Berlin/claude-impact-lab-berlin-2026-10-17)**. Read it first.
>
> ✅ **When you're finished:** record a 2-minute demo video, then submit with the **[submission form](https://tally.so/r/1WPr9Q)** before **16:00**. One submission per team.
>
> 🔑 Set your API key first: `cp .env.example .env`, then paste your key into `.env` (it's git-ignored, never commit it).

# Care Companion (working title) · by Team Out of Context

**One line:** A voice-first companion that helps older adults understand their medicines and appointments by showing AI a photo of their paperwork.

**Audience:** Older adults (roughly 70+) who take several medicines a day and get confusing paperwork from doctors and clinics, plus the adult children who help them.

**Their problem with AI today:** They have never used AI for anything useful, while being handed confusing paper all the time: medication plans, medicine boxes, appointment letters.

**What our demo lets them do:** Photograph a medication plan or a letter, check what the AI read, and get a simple, read-aloud daily schedule they can ask questions about.

## The problem
Many older people take several medicines a day, often from different doctors, and keep track of them on paper. Mixing up doses or forgetting what a tablet is for is common and risky, and the rest of the family worries about it. Reminder apps exist, but they expect people to type in drug names and schedules themselves, which is exactly the hard part.

## What it does
- **Show me a document:** take a photo of a medication plan, a medicine box or an appointment letter. Claude reads it and shows *"Here is what I read, is this right?"*; the user checks every line, removes mistakes and confirms.
- **My day:** a big, simple schedule (morning, midday, evening, night) with *Mark as taken* and *What is this?* (read aloud), plus upcoming appointments.
- **Ask a question:** "What is Ramipril for?", "What do I take this evening?", "Help me write questions for my doctor". Example questions teach people *how* to ask AI.

### Safety and privacy by design
- **Explains and organises, never advises.** Questions about changing, stopping or combining medicines, side effects or symptoms are answered with "please ask your doctor or pharmacist", and offered as a question for the next visit. Emergencies are pointed to 112.
- **Human check after every photo.** AI can misread; nothing is saved until the user confirms. That is also the lesson: always check what AI tells you.
- **Data stays on the device.** The confirmed plan lives in the browser (localStorage), with a *Delete my data* button. Only the photo or question being processed is sent to Claude.
- **Demo data is fictional.** See `samples/`.

## How Claude is used
Claude Opus 5.5 (`claude-opus-5-5`) via the Anthropic API, called from `server.js`:
- **Read document (vision):** reads a photo and returns structured JSON (document type, summary, medications with doses per time of day, appointments, anything unclear). Prompt: `prompts/read-document.md`.
- **Ask:** answers questions about the saved plan in plain, spoken-style English, within the safety rules above. Prompt: `prompts/ask.md`.

## How to run it
Needs Node.js 22 or newer.

```bash
cp .env.example .env    # paste your ANTHROPIC_API_KEY into .env
npm install
npm start               # then open http://localhost:3000
```

#### Better voice (optional)
Read-aloud uses the built-in macOS voice. For a warm, natural voice, run the local
[Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M) model (Apple Silicon Mac, needs [`uv`](https://docs.astral.sh/uv/)) in a second terminal:

```bash
npm run tts             # first start downloads the model (~350 MB) into ~/.cache/huggingface
```

It listens only on `127.0.0.1:3002`; the app uses it automatically and falls back to the macOS voice when it is not running.
Change the voice with `KOKORO_VOICE` (default `bf_emma`, British; try `af_heart` for American).

`npm run dev` restarts the server automatically when you change a file. Voice input works best in Chrome. No document at hand? Use *Try a sample plan* or *Try a sample letter* on the photo screen.

### Project layout (who owns what)

| Path | What it is | Owner |
|---|---|---|
| `server.js` | Small Node server: talks to Claude, keeps the API key secret | Gabriela |
| `prompts/` | Instructions for Claude (read document, ask) | Gabriela |
| `public/index.html` | The big-button, voice-first screen | Ahmad |
| `samples/` | Fictional sample documents (HTML source), rendered to `public/samples/*.png` | Lucas |
| `README.md` | This file, the pitch story | Valentina |

To re-render a sample after editing its HTML:
```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --hide-scrollbars \
  --window-size=1060,520 --screenshot="$PWD/public/samples/medication-plan.png" "file://$PWD/samples/medication-plan.html"
```

### Team rule: pull often, push often
- Start every task with `git pull --rebase`.
- After every small working step: commit, `git pull --rebase`, `git push`. Don't sit on changes for more than ~15 minutes.
- Claude Code follows this automatically (it's in `CLAUDE.md`). If you work on github.com directly, refresh before editing.

**Live link (if any):** <link>

## Screenshots / demo
<Drop screenshots here, or link your 2-minute demo video.>

## Team
Teams of 5 (at least 1 builder, 1 product or design, 1 domain expert; plus founder or anyone). Link each name to a GitHub or LinkedIn profile, and replace the example row with your team.

| Name | Role / background |
|---|---|
| Gabriela | Builder |
| Ahmad | Builder |
| Camila | Product design |
| Valentina | Founder |
| Lucas | Domain expert (videography) |

## Credits
- [Anthropic API](https://docs.claude.com) and the official [`@anthropic-ai/sdk`](https://github.com/anthropics/anthropic-sdk-typescript) (MIT)
- Browser Web Speech API for speech input and read-aloud
- All sample documents, names and addresses are fictional.
