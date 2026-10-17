# Scan test results

Run 2026-10-17 against the local server (`POST /api/chat`, real Claude), one call per document,
photo only (empty text). Context: Margaret's current 5-medicine plan (Ramipril, Metformin,
Simvastatin, ASS 100, Pantoprazole), `today` = Saturday, 17 October 2026, full profile.
All documents are fictional. Sources: `samples/test/*.html`; images: `public/samples/test/*.png`
(`blurry-plan.png` = `samples/medication-plan.html` rendered, cropped to 820x300, `boxblur=4:1`, slightly rotated).

**Overall: 6 PASS, 1 PARTIAL, 0 FAIL.** No guessed or invented values in any response.

## a. medicine-box-metformin.png — PASS

| | Expected | Got |
|---|---|---|
| Card | `confirm_medications`, `replaces_plan: false` | same |
| Medicine | Metformin 500 mg, morning 1, evening 1, with meals | "Metformin Lindenhof" 500 mg, morning "1", evening "1", instructions "Take 1 tablet twice daily with meals (morning and evening)" |
| Unclear | none | `[]` |
| Reply | short, check the card | "...This box is Metformin Lindenhof 500 mg, which is usually used for blood sugar... with your breakfast at 8 and your dinner at 6. Please check the card against the box..." |

Note: did not mention that Metformin is already on her plan, and used the brand name, so the card
may not match the existing "Metformin" entry (possible duplicate on save).

## b. medicine-box-new-amlodipine.png — PASS

| | Expected | Got |
|---|---|---|
| Card | `confirm_medications`, `replaces_plan: false` | same |
| Medicine | Amlodipine 5 mg, morning 1 | "Amlodipin Nordwerk" 5 mg, morning "1", purpose "for blood pressure" |
| Unclear | none | `[]` |
| Reply | flag it as new | "I read it as Amlodipin Nordwerk 5 mg for blood pressure, one tablet in the morning. Please check the card..." |

Note: did not say this medicine is NEW (not on her plan); brand name used as the medicine name.

## c. medication-plan-updated.png — PASS

| | Expected | Got |
|---|---|---|
| Card | `confirm_medications`, `replaces_plan: true` | same |
| Medicines | 6: Ramipril, Metformin, Atorvastatin 20 mg evening, ASS, Pantoprazole, Vitamin D 1000 IU morning | all 6 correct, doses/times correct, notes copied ("With meals", "After breakfast", "30 min before breakfast"); Atorvastatin purpose "for cholesterol (replaces Simvastatin)" |
| Unclear | none | `[]` |
| Reply | mention the change | "It has six medicines: five in the morning ... two in the evening..." |

Note: names given as "Brand (Ingredient)", e.g. "Ramipril-ratio (Ramipril)", inconsistent with
the stored plan ("Ramipril"). The reply did not point out that Simvastatin was swapped for
Atorvastatin and Vitamin D was added (only the card shows it).

## d. appointment-eye-clinic.png — PASS

| | Expected | Got |
|---|---|---|
| Card | `confirm_appointments` | same |
| Fields | Tue 3 Nov 2026, 10:15, eye clinic, bring glasses + insurance card, no driving | date "Tuesday, 3 November 2026", time "10:15", title "Eye examination with Dr. L. Brandt", place incl. floor, bring "All pairs of glasses ... health insurance card", preparation "Eye drops ... do not drive ..." |
| Reply | summary | "...on Tuesday the 3rd of November at 10:15. Bring all your glasses and your insurance card... don't drive. Perhaps Anna could go with you." |

Note: opened with "that was your first photo" (it can't know that; harmless).

## e. bank-letter.png — PASS

| | Expected | Got |
|---|---|---|
| Card | none, plain explanation | `cards: []` |
| Reply | new card coming, PIN separately, activate with PIN | "...your new bank card will come by post within a week, and your PIN will come in a separate letter... use it once at a cash machine or shop with your PIN, then cut the old card... The bank will never ask for your PIN by phone or email..." |

## f. handwritten-note.png — PASS

| | Expected | Got |
|---|---|---|
| Card | none (no strength given; Ramipril already on plan) | `cards: []` |
| Reading | Ramipril in the morning, call Anna at 6 | read correctly |
| Reply | explain the note | "...a lovely note from your daughter Anna, asking you to take your Ramipril in the morning and to give her a ring at 6 o'clock... the note doesn't say the strength, so could you show me the Ramipril box or your medication plan next..." |

Note: asks for the box although Ramipril (morning, 1) is already on her plan; it could have
confirmed "that matches your plan".

## g. blurry-plan.png — PARTIAL

| | Expected | Got |
|---|---|---|
| Card | `confirm_medications` with hard-to-read items in `unclear` (or nothing guessed) | no card |
| Unclear | blurred names/strengths listed | n/a |
| Reply | no guessing | "...the picture is too blurry for me to read the names and strengths safely, and the bottom looks cut off. Could you lay the paper flat in good light, hold the phone steady above it, and take the photo again?" |

Safe behaviour (nothing guessed, noticed the cut-off), but the `unclear` path was not used. A
retake request is arguably better for a fully blurred photo. The prompt should say which one we want.

## Suggested prompt improvements (prompts/chat.md, not applied)

1. **Medicine names:** "Use the active ingredient as `name` (e.g. "Metformin"); put the brand in
   `instructions` or leave it out." Today it mixes "Amlodipin Nordwerk", "Ramipril-ratio
   (Ramipril)", so matching against the stored plan can fail.
2. **Compare with the current plan:** "Before proposing, compare with their plan and say in one
   short sentence what is new, changed or already there (e.g. 'Amlodipine is new, it isn't on
   your plan yet'; 'Simvastatin has been replaced by Atorvastatin')." Seen in a, b, c, f.
3. **Blurry photos:** say which behaviour we want: "If you cannot read most of it, ask for a new
   photo and give no card; if only a few fields are unreadable, propose the rest and list those
   fields in `unclear`." This would make test g a deliberate PASS.
4. **Notes from family:** "If a note only repeats something already on the plan, say it matches."
   (f asked for the box unnecessarily.)
5. Minor: don't claim "that was your first photo" unless the history shows it (d).
