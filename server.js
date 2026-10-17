// Care Companion server: serves the screen in public/ and talks to Claude.
// The API key stays here on the server and never reaches the browser.
// Run: npm start   (reads ANTHROPIC_API_KEY from .env)

import http from "node:http";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import Anthropic from "@anthropic-ai/sdk";
import { transcribe, speak, voiceSettings } from "./voice.js";

const here = path.dirname(fileURLToPath(import.meta.url));
const PORT = Number(process.env.PORT) || 3000;
const MODEL = process.env.CLAUDE_MODEL || "claude-opus-5-5";
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

const DOCUMENT_SCHEMA = {
  type: "object",
  properties: {
    document_type: {
      type: "string",
      enum: ["medication_plan", "medicine_package", "appointment_letter", "other"],
    },
    summary: { type: "string" },
    medications: {
      type: "array",
      items: {
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
      },
    },
    appointments: {
      type: "array",
      items: {
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
      },
    },
    unclear: { type: "array", items: { type: "string" } },
  },
  required: ["document_type", "summary", "medications", "appointments", "unclear"],
  additionalProperties: false,
};

// ---------- Claude ----------

class RefusalError extends Error {}

// One place for every Claude request. `schema` makes Claude answer as JSON.
async function askClaude({ system, content, schema, effort = "low", maxTokens = 8000 }) {
  if (!client) throw new Error("NO_API_KEY");
  const response = await client.beta.messages.create({
    model: MODEL,
    max_tokens: maxTokens,
    system,
    messages: [{ role: "user", content }],
    output_config: {
      effort,
      ...(schema ? { format: { type: "json_schema", schema } } : {}),
    },
    // If a safety check declines, the API retries on a suitable model by itself.
    betas: ["server-side-fallback-2026-07-01"],
    fallbacks: "default",
  });
  if (response.stop_reason === "refusal") throw new RefusalError("refused");
  const text = response.content
    .filter((b) => b.type === "text")
    .map((b) => b.text)
    .join("");
  return schema ? JSON.parse(text) : text;
}

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
    return `- ${m.name} ${m.strength} (${m.purpose}); ${when}; ${m.instructions}`;
  });
  const appts = (plan.appointments || []).map(
    (a) => `- ${a.title}, ${a.date} ${a.time}, ${a.place}; bring: ${a.bring}; ${a.preparation}`,
  );
  return `Medications:\n${meds.join("\n") || "- none"}\n\nAppointments:\n${appts.join("\n") || "- none"}`;
}

// ---------- conversation (the phone app talks to this) ----------

const MEDICATION_ITEM = DOCUMENT_SCHEMA.properties.medications.items;
const APPOINTMENT_ITEM = DOCUMENT_SCHEMA.properties.appointments.items;
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
    name: "mark_taken",
    description: "Tick off medicines the user says they have taken.",
    input_schema: {
      type: "object",
      properties: { slot: SLOT, names: { type: "array", items: { type: "string" } } },
      required: ["slot", "names"],
      additionalProperties: false,
    },
  },
].map((t) => ({ ...t, strict: true }));

function runChatTool(name, input, cards, actions) {
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
    case "mark_taken":
      actions.push({ type: "mark_taken", ...input });
      return `Marked as taken (${input.slot}): ${input.names.join(", ")}.`;
    default:
      return `Unknown tool ${name}`;
  }
}

// history: [{ role: "user" | "assistant", text, image? }]; only the newest image is sent.
function historyToMessages(history) {
  const lastImage = history.findLastIndex((m) => m.image);
  return history.map((m, i) => {
    if (m.role === "assistant") return { role: "assistant", content: m.text || "…" };
    const content = [];
    if (m.image && i === lastImage) content.push(imageBlock(m.image));
    else if (m.image) content.push({ type: "text", text: "[The user showed a photo earlier.]" });
    content.push({ type: "text", text: m.text || (m.image ? "Here is a photo." : "…") });
    return { role: "user", content };
  });
}

async function chat({ history, plan, taken = {}, today, skills = [] }) {
  if (!client) throw new Error("NO_API_KEY");
  const system = [
    { type: "text", text: await readPrompt("chat.md"), cache_control: { type: "ephemeral" } },
    {
      type: "text",
      text: `Today: ${today || new Date().toDateString()}\n\nSaved plan:\n${planAsText(plan)}\n\nTaken today: ${JSON.stringify(taken)}\n\nAI skills the user has already practised: ${skills.join(", ") || "none yet"}`,
    },
  ];
  const messages = historyToMessages(history);
  const cards = [];
  const actions = [];
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
    const toolUses = response.content.filter((b) => b.type === "tool_use");
    if (response.stop_reason !== "tool_use" || !toolUses.length) {
      const reply = response.content.filter((b) => b.type === "text").map((b) => b.text).join("").trim();
      return { reply, cards, actions };
    }
    messages.push({ role: "assistant", content: response.content });
    messages.push({
      role: "user",
      content: toolUses.map((t) => ({
        type: "tool_result",
        tool_use_id: t.id,
        content: runChatTool(t.name, t.input, cards, actions),
      })),
    });
  }
  return { reply: "Here you are.", cards, actions };
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
  const rel = urlPath === "/" ? "index.html" : urlPath.slice(1);
  const file = path.normalize(path.join(here, "public", rel));
  if (!file.startsWith(path.join(here, "public"))) return sendJson(res, 403, { error: "Forbidden" });
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

  // Read a photo of a medication plan, a medicine box or an appointment letter.
  "POST /api/read-document": async (req, res) => {
    const { image } = await readJson(req);
    const result = await askClaude({
      system: await readPrompt("read-document.md"),
      content: [imageBlock(image), { type: "text", text: "Please read this document." }],
      schema: DOCUMENT_SCHEMA,
      effort: "medium", // reading accurately matters more than speed here
    });
    sendJson(res, 200, result);
  },

  // Answer a question about the saved plan ("What is this pill for?").
  "POST /api/ask": async (req, res) => {
    const { question, plan } = await readJson(req);
    if (!question || !question.trim()) {
      return sendJson(res, 400, { error: "Please type or say something first." });
    }
    const answer = await askClaude({
      system: await readPrompt("ask.md"),
      content: `My saved plan:\n${planAsText(plan)}\n\nMy question: ${question.trim()}`,
      maxTokens: 2000,
    });
    sendJson(res, 200, { answer });
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
    const { text } = await readJson(req);
    if (!text || !text.trim()) return sendJson(res, 400, { error: "Nothing to say." });
    const audio = await speak(text.trim().slice(0, 4000));
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

server.listen(PORT, "127.0.0.1", () => {
  console.log(`Care Companion running: http://localhost:${PORT}`);
  if (!client) console.log("Warning: no ANTHROPIC_API_KEY yet. The screen works, Claude calls will fail.");
});
