# Set up your laptop to work on Agatha

A copy-paste checklist for a Mac with Apple Silicon (M1 or newer). Do the steps in order.
Start step 2 (Xcode) first: it is the longest download, and you can do the other steps while it runs.

| Step | What | Time |
|---|---|---|
| 1 | Git access and clone | 5 min |
| 2 | Xcode 26 and the iOS Simulator | 30 to 60 min (download) |
| 3 | Homebrew tools | 5 to 10 min |
| 4 | Whisper speech model (optional) | 5 min |
| 5 | API key | 2 min |
| 6 | Run the helper server | 2 min |
| 7 | Run the app in the Simulator | 5 min |
| 8 | Real iPhone (optional) | 15 min |

Not a developer, or short on time? See [Working without the full setup](#working-without-the-full-setup).

---

## 1. Git access and clone (5 min)

1. Accept the GitHub invite: https://github.com/FOX-cOSMIC/out-of-context/invitations
2. Clone the repo:

```bash
git clone https://github.com/FOX-cOSMIC/out-of-context.git
cd out-of-context
```

## 2. Xcode 26 and the iOS Simulator (30 to 60 min, start this first)

1. Install **Xcode 26** from the Mac App Store (large download). Open it once and accept the licence.
2. Install the iOS Simulator platform (~8 GB), either in Terminal:

```bash
xcodebuild -downloadPlatform iOS
```

   or in *Xcode → Settings → Components*.
3. Check that the command-line tools point at Xcode:

```bash
xcode-select -p    # should print /Applications/Xcode.app/Contents/Developer
```

   If it prints something else: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`

## 3. Homebrew tools (5 to 10 min)

Install [Homebrew](https://brew.sh) if you do not have it, then:

```bash
brew install node xcodegen whisper-cpp ffmpeg uv
node --version     # needs v22 or newer
```

- `node`: runs the helper server (`server.js`)
- `xcodegen`: regenerates the Xcode project from `ios/project.yml`
- `whisper-cpp`, `ffmpeg`: local speech-to-text (fallback)
- `uv`: runs the optional Kokoro voice (`tts/server.py`)

## 4. Whisper speech model (5 min, optional)

On the phone and in the Simulator, your words are written down live by Apple's speech recognition, so this works without Whisper. Whisper on the Mac is the **fallback** when live transcription is off or unavailable. To set it up (~1.6 GB):

```bash
mkdir -p ~/.local/share/whisper
curl -L -o ~/.local/share/whisper/ggml-large-v3-turbo.bin \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin
```

Or put a different `ggml` model anywhere and set `WHISPER_MODEL=/path/to/model.bin` in `.env`.

## 5. API key (2 min)

Use your own key from the [Claude Console](https://console.anthropic.com), or one a teammate shares with you **privately** (direct message, not the group chat).

```bash
cp .env.example .env
open -e .env       # paste the key after ANTHROPIC_API_KEY= and save
```

`.env` is git-ignored. **Never commit it, and never paste a key into the group chat.**

## 6. Run the helper server (2 min)

```bash
npm install
npm start          # helper server on http://127.0.0.1:3000 (this Mac only)
```

Check it: open http://localhost:3000/api/health in a browser (shows whether the API key is set).
`npm run dev` restarts the server automatically when you change a file.

**Better voice (optional)**, in a second terminal:

```bash
npm run tts        # Kokoro voice on 127.0.0.1:3002; first run downloads ~340 MB
```

Without it, Agatha speaks with the built-in macOS voice. That is fine for development.

## 7. Run the app in the Simulator (5 min)

The Xcode project is committed, so normally you just open it:

```bash
open ios/CareCompanion.xcodeproj
```

Pick an iPhone simulator at the top of the Xcode window and press Run (▶). In the Simulator the app talks to `http://localhost:3000`, so keep `npm start` running.

Only if you **add or remove Swift files** (or edit `ios/project.yml`), regenerate the project and commit it:

```bash
cd ios && xcodegen generate
```

**Sample documents:** drag `public/samples/medication-plan.png` and `public/samples/appointment-letter.png` onto the Simulator window. They land in Photos, and you can pick them in the app's photo flow.

## 8. Real iPhone (15 min, optional)

1. *Xcode → Settings → Accounts*: add your Apple ID (a free one works).
2. Select the *CareCompanion* target → *Signing & Capabilities* → choose your team. **Do not commit your team ID** (leave `ios/project.yml` and the project file out of your commit if Xcode changed them for this).
3. Connect the iPhone and press Run. **Developer Mode** only appears on the phone after this first install attempt: *Settings → Privacy & Security* (at the bottom) → Developer Mode → on, then restart the phone.
4. If the app will not open: *Settings → General → VPN & Device Management* → trust your developer account.
5. The phone needs to reach a helper server. A real phone defaults to Lucas's Mac over his private Tailscale network, which you are not on. Instead, use **your own Mac over your own [Tailscale](https://tailscale.com)** network (see README, "The app on a real iPhone", for sharing port 3000 into your tailnet), and enter `http://<your Mac's Tailscale IP>:3000` under *Helper computer* in the app's Settings.

**Never** start the server with `HOST=0.0.0.0` on public or shared wifi: that opens it to everyone on the network.

---

## Working without the full setup

- **Designers:** all colours, fonts and sizes live in `ios/CareCompanion/Theme.swift`. You can also work in the design file `Medication Voice Assistant.html` (repo root, open it in a browser).
- **Non-engineers:** edit `README.md` directly on github.com (refresh before editing, since others push often).

## Team rules (recap)

- **Pull often, push often:** `git pull --rebase` before every task; after every small working step commit, `git pull --rebase`, `git push`.
- **Stay in your files** to avoid conflicts. Stage files by name (`git add <file>`), never `git add -A`, never commit `.env`.
- **Who owns what:**

| Area | Owner |
|---|---|
| `server.js`, `prompts/chat.md` | Gabriela |
| `ios/` (code) | Ahmad |
| `ios/CareCompanion/Theme.swift`, design | Camila |
| `README.md`, pitch | Valentina |
| `voice.js`, `tts/`, `samples/`, demo video | Lucas |

See "Project layout" in README.md for details.

## Troubleshooting

| Problem | Fix |
|---|---|
| Xcode says "iOS 26.x is not installed" | Download the platform: `xcodebuild -downloadPlatform iOS` or *Xcode → Settings → Components*. |
| The app says "I can't reach the helper right now" | The server is not running (`npm start`), or the app has the wrong address under *Helper computer* in Settings (Simulator: `http://localhost:3000` or empty). |
| Agatha replies but has no natural voice | Kokoro is not running. That is fine: the server falls back to the macOS voice. Run `npm run tts` if you want it. |
| Signing errors in Xcode | *Signing & Capabilities* → choose your own team (step 8). |
| "The assistant is not set up yet (API key missing)" | Check `.env` has `ANTHROPIC_API_KEY=...`, then restart `npm start`. |
| Push rejected | `git pull --rebase`, fix any conflicts, push again. |
