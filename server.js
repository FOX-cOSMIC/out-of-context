// Helper server for the Agatha iPhone app (ios/): the app sends the conversation here,
// this server talks to Claude and runs speech-to-text and text-to-speech on this Mac.
// The API key stays here on the server and never reaches the phone.
// It also serves the sample document photos in public/samples/.
// Run: npm start   (reads ANTHROPIC_API_KEY from .env)

import http from "node:http";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import Anthropic from "@anthropic-ai/sdk";
import { transcribe, speak, voiceSettings } from "./voice.js";

const here = path.dirname(fileURLToPath(import.meta.url));
const PORT = Number(process.env.PORT) || 3000;
// 127.0.0.1 = only this Mac. The real iPhone reaches it over Tailscale (see README); avoid HOST=0.0.0.0 on shared wifi.
const HOST = process.env.HOST || "127.0.0.1";
const MODEL = process.env.CLAUDE_MODEL || "claude-sonnet-5-5";
const MAX_BODY = 12 * 1024 * 1024; // photos arrive as base64 JSON

const client = process.env.ANTHROPIC_API_KEY ? new Anthropic() : null;

const readPrompt = (name) => fs.readFile(path.join(here, "prompts", name), "utf8");

// ---------- answer shapes Claude must return ----------

const TIMES = {
  type: "object",
  properties: {
    morning: { type: "string" },
    midday: { type: "string" },
    evening: { type: "string" },
    night: { type: "string" },
  },
  required: ["morning", "midday", "evening", "night"],
  additionalProperties: false,
};

// One medicine as read from a plan or box (used by the propose_medications tool).
const MEDICATION_ITEM = {
  type: "object",
  properties: {
    name: { type: "string" },
    strength: { type: "string" },
    purpose: { type: "string" },
    times: TIMES,
    instructions: { type: "string" },
  },
  required: ["name", "strength", "purpose", "times", "instructions"],
  additionalProperties: false,
};

// One appointment as read from a letter (used by the propose_appointments tool).
const APPOINTMENT_ITEM = {
  type: "object",
  properties: {
    title: { type: "string" },
    date: { type: "string" },
    time: { type: "string" },
    place: { type: "string" },
    bring: { type: "string" },
    preparation: { type: "string" },
  },
  required: ["title", "date", "time", "place", "bring", "preparation"],
  additionalProperties: false,
};

// ---------- Claude ----------

class RefusalError extends Error {}

// "data:image/jpeg;base64,AAAA" -> Claude image block
function imageBlock(dataUrl) {
  const match = /^data:(image\/(?:jpeg|png|webp|gif));base64,(.+)$/.exec(dataUrl || "");
  if (!match) throw new Error("BAD_IMAGE");
  return { type: "image", source: { type: "base64", media_type: match[1], data: match[2] } };
}

// The saved plan, as short text Claude can answer questions about.
function planAsText(plan = {}) {
  const meds = (plan.medications || []).map((m) => {
    const when = Object.entries(m.times || {})
      .filter(([, v]) => v)
      .map(([k, v]) => `${k}: ${v}`)
      .join(", ");
    return `- name: "${m.name}", strength: ${m.strength} (${m.purpose}); ${when}; ${m.instructions}`;
  });
  const appts = (plan.appointments || []).map(
    (a) => `- ${a.title}, ${a.date} ${a.time}, ${a.place}; bring: ${a.bring}; ${a.preparation}`,
  );
  return `Medications:\n${meds.join("\n") || "- none"}\n\nAppointments:\n${appts.join("\n") || "- none"}`;
}

// The "getting to know you" profile the phone keeps. All strings; "" = unknown.
const PROFILE_FIELDS = [
  "name", "address_as", "wake_time", "breakfast_time", "lunch_time", "dinner_time", "bed_time",
  "hearing", "eyesight", "tech_comfort", "helper_name", "helper_relation", "doctor_name",
];

const PROFILE_SCHEMA = {
  type: "object",
  properties: Object.fromEntries(PROFILE_FIELDS.map((f) => [f, { type: "string" }])),
  required: PROFILE_FIELDS,
  additionalProperties: false,
};

// The profile as short text for Claude; says plainly when nothing is known yet.
function profileAsText(profile) {
  const p = profile && typeof profile === "object" ? profile : {};
  const known = PROFILE_FIELDS.filter((f) => typeof p[f] === "string" && p[f].trim());
  if (!known.length) return "none yet (new user: no name known)";
  return PROFILE_FIELDS.map((f) => `- ${f}: ${(typeof p[f] === "string" && p[f].trim()) || "(unknown)"}`).join("\n");
}

// ---------- conversation (the phone app talks to this) ----------

const SLOT = { type: "string", enum: ["morning", "midday", "evening", "night"] };

// Tools Claude can use during the conversation. They don't change anything on the
// server: each one becomes a "card" or an "action" that the app shows or applies.
const CHAT_TOOLS = [
  {
    name: "show_schedule",
    description:
      "Show the user their medicines as a card in the chat. Use whenever they ask what to take, today or at a time of day.",
    input_schema: {
      type: "object",
      properties: { slot: { type: "string", enum: ["all", "morning", "midday", "evening", "night"] } },
      required: ["slot"],
      additionalProperties: false,
    },
  },
  {
    name: "show_appointments",
    description: "Show the user's saved appointments as a card in the chat.",
    input_schema: { type: "object", properties: {}, required: [], additionalProperties: false },
  },
  {
    name: "propose_medications",
    description:
      "After reading a photo of a medication plan or medicine box: show what you read as a card with Yes/No buttons so the user can check it. Nothing is saved until they tap Yes.",
    input_schema: {
      type: "object",
      properties: {
        replaces_plan: {
          type: "boolean",
          description: "true for a full medication plan from a doctor, false for a single medicine box",
        },
        medications: { type: "array", items: MEDICATION_ITEM },
        unclear: { type: "array", items: { type: "string" } },
      },
      required: ["replaces_plan", "medications", "unclear"],
      additionalProperties: false,
    },
  },
  {
    name: "propose_appointments",
    description:
      "After reading an appointment letter: show the appointment(s) as a card with Yes/No buttons. Nothing is saved until they tap Yes.",
    input_schema: {
      type: "object",
      properties: { appointments: { type: "array", items: APPOINTMENT_ITEM } },
      required: ["appointments"],
      additionalProperties: false,
    },
  },
  {
    name: "confirm_intake",
    description:
      "During a pill reminder call ONLY: the user clearly said they have ALREADY taken the medicines for this time of day (past tense, e.g. 'yes, I've taken them'). Ticks them off and lets the call end. Never use it for 'I will', 'later', 'soon' or unclear answers.",
    input_schema: {
      type: "object",
      properties: { slot: SLOT, names: { type: "array", items: { type: "string" } } },
      required: ["slot", "names"],
      additionalProperties: false,
    },
  },
  {
    name: "mark_taken",
    description: "Tick off medicines the user says they have taken. Use the names exactly as written in the saved plan.",
    input_schema: {
      type: "object",
      properties: { slot: SLOT, names: { type: "array", items: { type: "string" } } },
      required: ["slot", "names"],
      additionalProperties: false,
    },
  },
  {
    name: "save_profile",
    description:
      "Save what you learned about the user in the getting-to-know-you call. Only call this after you read the summary back and they agreed. Send all fields; use an empty string for anything unknown or skipped.",
    input_schema: PROFILE_SCHEMA,
  },
  {
    name: "open_screen",
    description:
      "Open a screen of the app for the user. Use when they ask to see it: \"show me my pills\" -> pills, \"I want to scan a letter\" -> scan, \"I need help\" or an emergency -> sos, \"my notes\" or \"my papers\" -> notes, \"back to Agatha\" -> home. Then say which screen you opened.",
    input_schema: {
      type: "object",
      properties: { screen: { type: "string", enum: ["home", "pills", "scan", "notes", "sos"] } },
      required: ["screen"],
      additionalProperties: false,
    },
  },
  {
    name: "save_note",
    description:
      "Write a note into the user's Notes on the phone. Use when they ask you to note or write something down, or agree to your offer to note it for the doctor. kind: doctor_questions for questions to ask the doctor, feeling for how they feel or a symptom, note for anything else. title is a few plain words; text is their words, short and clear. Then say what you saved.",
    input_schema: {
      type: "object",
      properties: {
        title: { type: "string" },
        text: { type: "string" },
        kind: { type: "string", enum: ["note", "doctor_questions", "feeling"] },
      },
      required: ["title", "text", "kind"],
      additionalProperties: false,
    },
  },
  {
    name: "save_document",
    description:
      "Keep the photo the user showed most recently (a letter, bill or form) in \"My papers\" on the phone, with a short title and a one or two sentence plain summary. Only call this after the user said yes to keeping it. Then say it is kept in Notes, under My papers.",
    input_schema: {
      type: "object",
      properties: { title: { type: "string" }, summary: { type: "string" } },
      required: ["title", "summary"],
      additionalProperties: false,
    },
  },
].map((t) => ({ ...t, strict: true }));

function runChatTool(name, input, cards, actions, hasPhoto = false) {
  switch (name) {
    case "show_schedule":
      cards.push({ type: "schedule", slot: input.slot });
      return "The schedule card is now on screen.";
    case "show_appointments":
      cards.push({ type: "appointments" });
      return "The appointments card is now on screen.";
    case "propose_medications":
      cards.push({ type: "confirm_medications", ...input });
      return "The card with Yes/No buttons is on screen. Ask the user to check each line against their paper.";
    case "propose_appointments":
      cards.push({ type: "confirm_appointments", ...input });
      return "The card with Yes/No buttons is on screen. Ask the user to check it.";
    case "confirm_intake":
      actions.push({ type: "mark_taken", slot: input.slot, names: input.names });
      actions.push({ type: "confirm_intake", slot: input.slot, names: input.names });
      return `Confirmed and ticked off (${input.slot}): ${input.names.join(", ")}. Thank them warmly in one short sentence and say goodbye; the call ends by itself.`;
    case "mark_taken":
      actions.push({ type: "mark_taken", ...input });
      return `Marked as taken (${input.slot}): ${input.names.join(", ")}.`;
    case "save_profile":
      actions.push({ type: "save_profile", profile: input });
      return "Profile saved on the phone.";
    case "open_screen":
      actions.push({ type: "open_screen", screen: input.screen });
      return `The ${input.screen} screen is now open on the phone. Tell the user what they see there.`;
    case "save_note":
      actions.push({ type: "save_note", title: input.title, text: input.text, kind: input.kind });
      return `Saved in the user's Notes: "${input.title}". Tell them what you wrote down.`;
    case "save_document":
      if (!hasPhoto) return "There is no photo in this conversation to keep. Nothing was saved; ask the user to show the paper first.";
      actions.push({ type: "save_document", title: input.title, summary: input.summary });
      return `The photo is kept in Notes, under My papers, as "${input.title}".`;
    default:
      return `Unknown tool ${name}`;
  }
}

// history: [{ role: "user" | "assistant", text, image? }]; only the newest image is sent.
function historyToMessages(history) {
  const lastImage = history.findLastIndex((m) => m.image?.startsWith("data:"));
  return history.map((m, i) => {
    if (m.role === "assistant") return { role: "assistant", content: m.text || "…" };
    const content = [];
    if (m.image && i === lastImage) content.push(imageBlock(m.image));
    else if (m.image) content.push({ type: "text", text: "[The user showed a photo earlier.]" });
    content.push({ type: "text", text: m.text || (m.image ? "Here is a photo." : "…") });
    return { role: "user", content };
  });
}

// The notes saved on the phone, as short text (newest 10, long texts trimmed).
function notesAsText(notes) {
  if (!Array.isArray(notes) || !notes.length) return "none yet";
  const trim = (s, n) => (typeof s === "string" && s.length > n ? `${s.slice(0, n)}…` : s || "");
  return notes
    .slice(-10)
    .map((n) => `- [${trim(n.kind, 30)}] ${trim(n.date, 40)} "${trim(n.title, 100)}": ${trim(n.text, 200)}`)
    .join("\n");
}

// The app's short history and calendar text (at most ~900 characters; trimmed here too).
function historySummaryAsText(summary) {
  if (typeof summary !== "string" || !summary.trim()) return "none";
  return summary.length > 1200 ? `${summary.slice(0, 1200)}…` : summary;
}

async function chat({ history, plan, taken = {}, today, skills = [], profile, notes = [], history_summary }) {
  if (!client) throw new Error("NO_API_KEY");
  const system = [
    { type: "text", text: await readPrompt("chat.md"), cache_control: { type: "ephemeral" } },
    {
      type: "text",
      text: `Today: ${today || new Date().toDateString()}\n\nUser profile:\n${profileAsText(profile)}\n\nSaved plan:\n${planAsText(plan)}\n\nTaken today: ${JSON.stringify(taken)}\n\nAI skills the user has already practised: ${skills.join(", ") || "none yet"}\n\nNotes saved on the phone (newest last):\n${notesAsText(notes)}\n\nRecent history and calendar:\n${historySummaryAsText(history_summary)}`,
    },
  ];
  // The app can only keep a photo the user really sent (only the newest one is kept).
  const hasPhoto = history.some((m) => typeof m.image === "string" && m.image.length > 0);
  const messages = historyToMessages(history);
  const cards = [];
  const actions = [];
  const said = []; // text from every step, so words written next to a tool call are kept
  const textOf = (response) =>
    response.content.filter((b) => b.type === "text").map((b) => b.text).join("").trim();
  for (let turn = 0; turn < 6; turn++) {
    const response = await client.beta.messages.create({
      model: MODEL,
      max_tokens: 8000,
      system,
      tools: CHAT_TOOLS,
      messages,
      output_config: { effort: "low" },
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
    });
    if (response.stop_reason === "refusal") throw new RefusalError("refused");
    const text = textOf(response);
    if (text) said.push(text);
    const toolUses = response.content.filter((b) => b.type === "tool_use");
    if (response.stop_reason !== "tool_use" || !toolUses.length) {
      return { reply: said.join(" "), cards, actions };
    }
    messages.push({ role: "assistant", content: response.content });
    messages.push({
      role: "user",
      content: toolUses.map((t) => ({
        type: "tool_result",
        tool_use_id: t.id,
        content: runChatTool(t.name, t.input, cards, actions, hasPhoto),
      })),
    });
  }
  return { reply: said.join(" ") || "Here you are.", cards, actions };
}

// ---------- HTTP ----------

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".ico": "image/x-icon",
};

function sendJson(res, status, body) {
  res.writeHead(status, { "Content-Type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(body));
}

async function readJson(req) {
  let raw = "";
  for await (const chunk of req) {
    raw += chunk;
    if (raw.length > MAX_BODY) throw new Error("TOO_LARGE");
  }
  return raw ? JSON.parse(raw) : {};
}

async function readBuffer(req) {
  const chunks = [];
  let size = 0;
  for await (const chunk of req) {
    size += chunk.length;
    if (size > MAX_BODY) throw new Error("TOO_LARGE");
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}

async function serveStatic(req, res) {
  const urlPath = decodeURIComponent(new URL(req.url, "http://x").pathname);
  if (urlPath === "/") {
    res.writeHead(200, { "Content-Type": "text/plain; charset=utf-8" });
    return res.end("Agatha helper server is running. Open the Agatha app on the iPhone.\n");
  }
  const rel = urlPath.slice(1);
  const file = path.normalize(path.join(here, "public", rel));
  if (!file.startsWith(path.join(here, "public") + path.sep)) return sendJson(res, 403, { error: "Forbidden" });
  try {
    const data = await fs.readFile(file);
    res.writeHead(200, { "Content-Type": MIME[path.extname(file)] || "application/octet-stream" });
    res.end(data);
  } catch {
    sendJson(res, 404, { error: "Not found" });
  }
}

// Friendly messages for the screen; details go to the terminal.
function friendlyError(res, err) {
  const known = {
    NO_API_KEY: [503, "The assistant is not set up yet (API key missing)."],
    BAD_IMAGE: [400, "That photo did not work. Please try another one."],
    TOO_LARGE: [413, "That photo is too large. Please try again."],
  };
  if (known[err.message]) {
    if (err.message === "NO_API_KEY") console.error("No ANTHROPIC_API_KEY. Put it in .env and restart.");
    const [status, error] = known[err.message];
    return sendJson(res, status, { error });
  }
  if (err instanceof RefusalError) {
    return sendJson(res, 200, {
      error: "Sorry, I cannot help with that one. Please ask your doctor or pharmacist.",
    });
  }
  console.error(err);
  return sendJson(res, 502, { error: "That did not work just now. Please try again." });
}

const routes = {
  // The phone app's conversation: text and/or a photo in, a reply plus cards out.
  "POST /api/chat": async (req, res) => {
    const body = await readJson(req);
    if (!Array.isArray(body.history) || !body.history.length) {
      return sendJson(res, 400, { error: "Please type or say something first." });
    }
    sendJson(res, 200, await chat(body));
  },

  // Local speech-to-text on this Mac (Whisper). Body: the raw recorded audio.
  "POST /api/transcribe": async (req, res) => {
    const audio = await readBuffer(req);
    if (!audio.length) return sendJson(res, 400, { error: "I did not hear anything. Please try again." });
    const text = await transcribe(audio);
    sendJson(res, 200, { text });
  },

  // Local text-to-speech on this Mac (macOS voices). Returns m4a audio.
  "POST /api/speak": async (req, res) => {
    const { text, rate } = await readJson(req);
    if (!text || !text.trim()) return sendJson(res, 400, { error: "Nothing to say." });
    // Optional speaking speed in words per minute, kept to a comfortable 120-220.
    const wpm = Number.isFinite(rate) ? Math.min(220, Math.max(120, Math.round(rate))) : undefined;
    const audio = await speak(text.trim().slice(0, 4000), wpm);
    res.writeHead(200, { "Content-Type": "audio/mp4", "Content-Length": audio.length });
    res.end(audio);
  },

  "GET /api/health": async (_req, res) => {
    sendJson(res, 200, { ok: true, apiKey: Boolean(client), model: MODEL, voice: voiceSettings });
  },
};

const server = http.createServer(async (req, res) => {
  const pathname = new URL(req.url, "http://x").pathname;
  const handler = routes[`${req.method} ${pathname}`];
  try {
    if (handler) return await handler(req, res);
    if (req.method === "GET") return await serveStatic(req, res);
    sendJson(res, 404, { error: "Not found" });
  } catch (err) {
    friendlyError(res, err);
  }
});

server.listen(PORT, HOST, () => {
  console.log(`Agatha helper server running: http://${HOST === "0.0.0.0" ? "<this Mac's IP>" : "localhost"}:${PORT}`);
  if (!client) console.log("Warning: no ANTHROPIC_API_KEY yet. Voice works, Claude calls will fail.");
});
