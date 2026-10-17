# Agatha's abilities inside the app

Agatha talks to Claude on the server. Claude can use **tools**; each tool becomes a card
or an action that the phone applies (`CHAT_TOOLS` / `runChatTool` in `server.js`,
`ChatModel.apply` on the phone). Rule for every ability: **nothing calls, sends or shares
anything without the user tapping**, and Agatha always says out loud what she did.

| Ability | Value for an older user | Risk | Needs confirmation? | Status |
|---|---|---|---|---|
| Open a screen (`open_screen`) | "Show me my pills", "I need help" just works, no hunting for buttons | Low: only switches tabs | No (the user asked) | **Built** |
| Save a note (`save_note`, kind `note`/`feeling`) | "Note that I felt dizzy": a record to show the doctor | Low: stays on the phone | No when asked; yes when Agatha offers | **Built** |
| Questions for my doctor (`save_note`, kind `doctor_questions`) | Questions ready for the next visit, shown as "For Dr Hoffmann" | Low | Same as above | **Built** |
| Keep a scanned letter (`save_document`) | Letters stop getting lost; photo plus a plain summary in "My papers" | Low: photo stays on the phone | **Yes**: Agatha asks "Shall I keep this letter?" first | **Built** |
| Add medicines / appointments from a photo | No typing drug names | Medium: a misread dose | **Yes**: Yes/No card | Already built |
| Mark medicines taken (`mark_taken`) | "I took my morning pills" | Low-medium: a wrong tick | No (the user said it); visible on the schedule card | Already built |
| Read today's plan (`show_schedule`) | "What do I take tonight?" | Low | No | Already built |
| Set a reminder (local notification) | Medicine and appointment alarms | Medium: a missed or wrong alarm | Yes, show time and tap to set | Later |
| Call the helper / doctor | One sentence to reach Anna | **High**: unwanted calls | **Always** a tap on a big button; Agatha may only open SOS | Later (only via SOS screen) |
| Share a note with family | Anna sees the doctor questions | High: privacy | Always: the iOS share sheet, the user picks who | Later |
| Edit / delete notes by voice | Tidy up without small buttons | Medium: deleting the wrong thing | Yes | Later (delete by button for now) |

## What is built

- **open_screen** `{screen: home|pills|scan|notes|sos}`: the phone sets `ChatModel.pendingTab`,
  `RootView` switches the tab (home = `Navigator.goHome()`).
- **save_note** `{title, text, kind}`: stored as `SavedNote` in UserDefaults (`notes`).
- **save_document** `{title, summary}`: the newest photo the user sent is saved as a JPEG in the
  app's Documents folder, listed as `SavedPaper` in UserDefaults (`papers`). The server refuses
  the tool when the conversation has no photo.
- **Notes screen**: "My notes" (newest first, kind label, date) and "My papers" (thumbnail, tap
  for the full photo), each with a Delete button and an "are you sure" question.
- The app sends the newest 10 notes (text trimmed to 200 characters) with every chat request,
  so Agatha knows what is already written down.
