> 👋 **Starter for Claude Impact Lab teams.** Fill in each section below as you build and delete this note.
>
> 📅 **Agenda, rules, deadline and judging** are in the event repo: **[claude-impact-lab-berlin-2026-10-17](https://github.com/Claude-Community-Berlin/claude-impact-lab-berlin-2026-10-17)**. Read it first.
>
> ✅ **When you're finished:** record a 2-minute demo video, then submit with the **[submission form](https://tally.so/r/1WPr9Q)** before **16:00**. One submission per team.
>
> 🔑 Set your API key first: `cp .env.example .env`, then paste your key into `.env` (it's git-ignored, never commit it).

# Scam Shield (working title) · by Team Out of Context

**One line:** A voice-first helper that lets older adults in Germany check a suspicious call or message with AI, and practise spotting scams safely.

**Audience:** Older adults (roughly 70+), starting in Germany, who get scam calls on their landline or phone, plus their adult children who help them with tech.

**Their problem with AI today:** They mostly hear about AI as a threat (voice-cloned "shock calls", fake police officers) and have never used it to protect themselves.

**What our demo lets them do:** Describe a call or show a message, get a plain-English verdict and one clear next step, and practise hanging up on an AI playing the scammer.

## The problem
Phone scams on older people are rising in Germany: according to BKA figures reported in the press, fake police officers took about €49.5M in 2025 (up from €30.1M), and the grandchild trick and shock calls about €49.0M. The costliest scams arrive by phone, often on a landline, where existing text-only scam checkers don't help. Research suggests short, repeated practice works better than one-off warnings.

## What it does
- **Check a call or message:** describe what happened (typing or speaking), get a plain-English verdict (scam / suspicious / safe), the warning signs, one clear next step, and a tip to remember. The answer is read aloud.
- **Practise:** pick a scenario (fake police officer, shock call, "Hi Mum, new number"). Claude plays the caller; you answer by voice or text, press *Hang up* and get kind feedback on what you did well and what to watch for.

## How Claude is used
Claude Opus 5.5 (`claude-opus-5-5`) via the Anthropic API, called from `server.js`:
- **Scam check:** reads the user's description of a call or message and returns structured JSON (verdict, why, next step, learning tip). Prompt: `prompts/check.md`.
- **Practice caller:** role-plays a scammer from a scenario file, mildly, and stops if real personal data appears. Prompt: `prompts/practice-caller.md`.
- **Coach:** reviews the practice call and returns encouraging feedback as JSON. Prompt: `prompts/practice-feedback.md`.

## How to run it
Needs Node.js 22 or newer.

```bash
cp .env.example .env    # paste your ANTHROPIC_API_KEY into .env
npm install
npm start               # then open http://localhost:3000
```

`npm run dev` restarts the server automatically when you change a file. Voice input works in Chrome, Edge and Safari.

### Project layout (who owns what)

| Path | What it is | Owner |
|---|---|---|
| `server.js` | Small Node server: talks to Claude, keeps the API key secret | Gabriela |
| `prompts/` | Instructions for Claude (check, practice caller, coach) | Gabriela |
| `public/index.html` | The big-button, voice-first screen | Ahmad |
| `scenarios/` | Fake scam scenarios for practice and the demo (one JSON file each) | Lucas |
| `README.md` | This file, the pitch story | Valentina |

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
- Scam patterns: [Verbraucherzentrale](https://www.verbraucherzentrale.de/wissen/digitale-welt/mobilfunk-und-festnetz/hallo-mama-hallo-papa-betrugsversuche-ueber-whatsapp-und-sms-72910), BKA figures as reported by German press. All scenarios are fictional.
