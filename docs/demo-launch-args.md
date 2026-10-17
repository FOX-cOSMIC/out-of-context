# Demo launch arguments (record the video without tapping)

The iOS app reads these launch arguments (code: `ios/CareCompanion/DemoLaunch.swift`, call hooks in
`ios/CareCompanion/CallScheduler.swift`). They work in Debug and Release builds.

| Argument | What it does |
|---|---|
| `-demoReset` | Start clean as Margaret with her demo plan and appointments (like Settings → delete all data), with the greeting bubble. |
| `-demoTab <pills\|scan\|home\|notes\|sos>` | Open that tab after launch (`talk` also means home). |
| `-demoSheet <history\|calendar>` | Open the Pills tab and then "My week & month" (`history`) or "My calendar" (`calendar`). |
| `-demoAsk "<text>"` | After 2.5 s, send this text to Agatha as if typed: the real answer, voice and card play. |
| `-demoAskDelay <seconds>` | Change the 2.5 s delay (used by `-demoAsk` and `-demoScan`). |
| `-demoScan <path\|sample-plan\|sample-amlodipine\|sample>` | After 2.5 s, send this photo to Agatha. A path is absolute or relative to the app's Documents folder. `sample-plan` (= `sample`) is `public/samples/medication-plan.png`, `sample-amlodipine` is `public/samples/test/medicine-box-new-amlodipine.png` (both bundled in the app). |
| `-demoTapYes` | When a "Here is what I read" card appears, tap "Yes, right" by itself: at least 4 s after the card appears and once Agatha has stopped speaking. |
| `-testCall` | Agatha's pill reminder call rings 3 s after launch. |
| `-testCallAccept` | With `-testCall` (Debug builds): the call picks up by itself after 3 s of ringing. |
| `-testFamilyCall` | Shows "Calling Anna" (the family call) right away. |

The helper server must be running (`npm start`, the Simulator uses `localhost:3000`) for anything Agatha says.

## Recording one scene

```sh
SIM=0ABA0E8B-75E5-4C3C-A2C2-0F47D3980443   # the iPhone 17 simulator used for recordings
APP=com.outofcontext.carecompanion
xcrun simctl terminate $SIM $APP            # always start from a cold launch
xcrun simctl io $SIM recordVideo --codec h264 01-home.mp4 &   # stop with: kill -INT %1
xcrun simctl launch $SIM $APP -demoReset
```

Own photo for the scan scene: copy it into the app's Documents folder first, then pass its name.

```sh
DOCS="$(xcrun simctl get_app_container $SIM $APP data)/Documents"
cp my-photo.png "$DOCS/" && xcrun simctl launch $SIM $APP -demoReset -demoScan my-photo.png -demoTapYes
```

## The video scenes

| Scene | Launch command (after `terminate`, with `recordVideo` running) |
|---|---|
| 01-home | `xcrun simctl launch $SIM $APP -demoReset` |
| 02-call-ringing | `xcrun simctl launch $SIM $APP -demoReset -testCall` |
| 03-call-conversation | `xcrun simctl launch $SIM $APP -demoReset -testCall -testCallAccept` |
| 04-scan | `xcrun simctl launch $SIM $APP -demoReset -demoScan sample-amlodipine -demoTapYes` |
| 05-safety-question | `xcrun simctl launch $SIM $APP -demoReset -demoAsk "Can I skip my Metformin today?"` |
| 06-week-summary | `xcrun simctl launch $SIM $APP -demoReset -demoAsk "How did I do with my pills this week?"` |
| 07-pills-history | `xcrun simctl launch $SIM $APP -demoReset -demoTab pills -demoSheet history` |
| 08-calendar | `xcrun simctl launch $SIM $APP -demoReset -demoTab pills -demoSheet calendar` |
| 09-family-call | `xcrun simctl launch $SIM $APP -demoReset -testFamilyCall` |
| 10-sos | `xcrun simctl launch $SIM $APP -demoReset -demoTab sos` |
