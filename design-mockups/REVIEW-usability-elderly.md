# Agatha mockups: usability review for older adults (70+)

Reviewer lens: gerontechnology and WCAG 2.2, with Margaret in mind (78, slightly hard of hearing, reads with glasses, new to smartphones, a bit nervous).
Sources: A/B/C `.png` plus the CSS in each `.html`, and the current shipped home screen (`sim-talk2.png`).
Sizes are CSS px at 393pt width, so 1px ≈ 1pt.

## Contrast ratios computed from the CSS (WCAG: 4.5 normal text, 3.0 large text, 7.0 for AAA)

| Pair | Where | Ratio | Verdict |
|---|---|---|---|
| ink #1E1B2E on off-white #FAF9F5 | body text, all three | 15.9 | AAA |
| ink2 #4A4560 on white | A/B tab labels and secondary text | 9.1 | AAA |
| white on purple #6B3FE0 | A/B main buttons | 6.2 | AA, not AAA |
| white on purple-d #3E1F99 | C main buttons | 11.3 | AAA |
| white on green-d #0B5D46 | C "DONE" / "Yes, I took it" | 7.9 | AAA |
| purple on lavender #EFE6FF | A "Send a help message", "Speaking" link | 5.1 | AA only |
| white / red #C8283A | Call 112 button, SOS tab label | 5.5 | AA only |
| mint-d #1C7A62 on mint | A "Done" chip (small, 15–16px) | 4.7 | borderline AA |
| #B44A14 on peach | B "I'm listening…" | 4.8 | AA only |
| ink on orange #FF7A3D | C listening banner | 6.5 | AA (large) |
| **#B7B0C8 on off-white** | **A: unconfirmed words while listening** | **2.0** | **FAIL** |
| **#8A84A3 on white** | **B: unconfirmed words while listening** | **3.6** | **fails body text** (passes only because it is 30px) |
| **white on orange #FF7A3D** | **B: "Listening" tab icon/label** | **2.6** | **FAIL** |

---

## Direction A: Calm minimal

Tab labels 15px, tab target 70×58px, talk pill 56–60px tall, body 17–20px, answer 27px.

| Sev | Issue | Fix |
|---|---|---|
| High | Live words fade to #B7B0C8 (contrast 2.0). The half of the sentence she most needs to check is the half she can't read. | Show all words in ink; mark the unconfirmed tail with an underline or a blinking cursor, never with pale grey. |
| High | The listening state only shows as a small "I'm listening…" pill and a lavender wave. With no strong colour change, a hard-of-hearing user may miss that the mic is on. | Add a full-width coloured state banner with words, like C's "Agatha is listening. Tap DONE…". |
| High | The keyboard button next to Tap to talk is icon only. | Label it "Type". |
| Med | Tab labels are 15px and secondary text is 15–17px, below the 18pt floor. | Use at least 17–18px for tab labels and at least 18px for secondary text. |
| Med | The two "Take" buttons on the answer card sit only about 14px apart and act at once with no undo shown. | Space them at least 16px apart and show "Taken ✓ · Undo" for 10s or more after a tap. |
| Med | The speaker button (top right) is icon only, and the "tap to hear again" link is small purple text (5.8:1). | Use a labelled "Say it again" button at least 56px tall, as in C. |
| Med | The SOS screen doesn't say whether "Call 112" dials straight away. | Add one confirmation step ("Call 112 now?", Yes/No), and say on screen that it will ask. |
| Low | "Done" and "Later" chips are small (≈15px) and coloured, and "Done" is only 4.7:1. | Make them bigger and add an icon (✓ / clock). |
| Low | Home is nearly empty apart from the next-pills card. Calm, but there is little to reassure her. | Fine as is; consider adding "Everything's on track today". |

## Direction B: Warm companion

Body 18–22px, buttons at least 56px, tab labels 15px, robot hero 300px+, raised centre tab.

| Sev | Issue | Fix |
|---|---|---|
| High | The talk control is the robot illustration with a small "Tap me and ask" chip. New users often don't see a picture as a button, and they tap the chip, which is only about 48px. | Keep the robot but put a full-width labelled "Tap to talk" button under it. |
| High | The centre tab changes name and meaning (Home, Listening, Home, Agatha, Agatha) and turns orange with white text (2.6:1). It is inconsistent and hard to read. | Give it one fixed name ("Home") and show listening state in the page, not in the tab bar. |
| High | Live words in #8A84A3 (3.6:1). | Use ink plus a cursor, as in A's fix. |
| Med | "Stop" (outlined) sits right beside "I'm done". It's easy to hit the wrong one, and the difference is unclear (does Stop throw away her words?). | Stack them vertically, or label them "Send" vs "Cancel". |
| Med | The pills screen is dense: six items, coloured bands, small sub-lines (17px). Higher cognitive load. | Collapse finished doses and show only "Now" expanded. |
| Med | The call buttons on the SOS screen are round icons (≈56px) with no word on them. | Add text to each button ("Call Anna"). |
| Med | The red filled SOS tab is next to the raised Agatha tab, a mis-tap risk on the most consequential control. | Add a confirmation step for 112 and at least 12px of clear space next to SOS. |
| Low | Decoration (flowers, rings) adds visual noise for low vision. | Reduce it on screens other than Home. |
| Low | Atkinson Hyperlegible is used: a good choice. | Keep it. |

## Direction C: Maximum accessibility

Body 19–24px, answers 27–32px, main buttons 68–150px, tab labels 16px in ink, 3px card outlines, every icon has a word.

| Sev | Issue | Fix |
|---|---|---|
| Med | ALL-CAPS labels ("TAP TO TALK", "DONE", "YOUR NEXT PILLS") read more slowly and can feel like shouting to a nervous user. | Use sentence case at the same size and weight. |
| Med | Tab labels are still 16px. | Use 17–18px, or drop to 4 tabs so there is room (see the tab note below). |
| Med | Heavy black outlines everywhere make it look clinical and busy. | Use 2px outlines and keep 3px only on the main action. |
| Med | The "Take" buttons in the answer card are about 64px wide, next to multi-line text. | Make each "Take" a full-width row button. |
| Low | The orange listening banner works, but orange is also the "now" colour elsewhere. | Fine; keep colours consistent everywhere. |
| Low | It already says it confirms before calling 112: correct. | Make sure the confirm dialog buttons are at least 64px. |
| Low | The answer screen has three stacked blocks (status, You said, answer, card, Say it again) and can overflow. | Allow scrolling, and keep "Say it again" pinned. |

## Tab bar (all three)

Five tabs at 393pt leave about 70–78pt each. That is fine for tap size, but labels are stuck at 15–16px.
Margaret will mostly use Home and Pills. Scan and Notes are rarely used, and SOS is the one with real consequences.
- Recommended: 4 tabs (Home, Pills, Notes, SOS), with Scan offered from the Pills screen and as "Scan a box" in voice answers. Or keep 5 but give SOS at least 12pt of clear space.
- Notes uses a heart icon in the current app and a document icon in the mockups. Use one icon everywhere (document), because a heart reads as "health" or "favourites".

## Ranking for older users

1. **C, Maximum accessibility.** Best contrast (AAA), biggest targets, every control labelled, state shown in words, and it confirms before calling 112. Soften the all-caps and the outlines and it is the safest base.
2. **A, Calm minimal.** Lowest cognitive load and the calmest, but the faded live text, icon-only controls and weak listening state need fixing.
3. **B, Warm companion.** The most charming, but "the picture is the button", the shape-shifting centre tab and the 2.6:1 orange tab make it the riskiest for a nervous first-time user.

Best blend: C's structure, labels and state banners, A's calm spacing and sentence case, and B's warm "Well done, Margaret!" wording and Atkinson Hyperlegible.

---

## Current shipped home screen: risks

- **Settings gear (top right) is icon only and easy to tap by accident.** It leads to a place where she can break things.
- **Date "17 Oct" is small mid-grey text and abbreviated.** It needs to be larger, in ink, and spelled out ("Friday, 17 October"). Older users rely on the date to know which pills are today's.
- **No "next pills" card.** Home doesn't answer the question she opened the app for. The space between the greeting and the button is empty.
- **"Type" (≈190×170px) sits right next to "Tap to talk".** That's fine for size, but it competes as a second main action.
- **The raised Home tab sits directly under the Tap to talk button, with little gap.** Tapping just below the talk button lands on Home.
- **Notes has a heart icon**, which doesn't match what it does.
- **SOS sits at the edge next to Notes, with only a pink tint as a buffer.** It's unclear whether one tap dials.
- **Nothing shows the listening or speaking state** on this screen. Check that the in-call states have a visible banner, not just audio.
- Positives: large greeting (≈36pt), a "Tap to talk" label with the sub-line "then speak to Agatha", text under every tab icon, and good ink contrast.

## Top 7 usability fixes for the CURRENT app (priority order)

1. Make "Call 112" ask once more before dialling ("Call 112 now?" with large Yes/No buttons), and say on the SOS screen that it will ask.
2. While listening, show a full-width coloured banner with words ("Agatha is listening. Tap Done when you've finished"), and while she speaks show "Agatha is speaking · Say it again", so state never depends on hearing.
3. Show every live and "You said" word in full-contrast ink at 24pt or more (never pale grey), so she can catch a mishearing before acting on it.
4. After every "Yes, I took it" or "Take", show "Taken at 8:02 ✓, Undo" for at least 10 seconds, and keep an undo in the Pills list for the rest of the day.
5. Add a "Next pills: 6 pm, Metformin and Simvastatin" card in the empty middle of Home, so the screen answers her most common question without speaking.
6. Give every icon-only control a text label (put "Settings" under the gear or move it into a menu, and label the keyboard and speaker buttons), and change the Notes heart to a notepad icon.
7. Raise tab labels and secondary text to at least 18pt, show the date in ink as "Friday, 17 October", and leave at least 16pt between the talk button, the raised Home tab and SOS (or drop Scan from the tab bar to make room).
