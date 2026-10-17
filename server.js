// Scam Shield server: serves the screen in public/ and talks to Claude.
// The API key stays here on the server and never reaches the browser.
// Run: npm start   (reads ANTHROPIC_API_KEY from .env)

import http from "node:http";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import Anthropic from "@anthropic-ai/sdk";

const here = path.dirname(fileURLToPath(import.meta.url));
const PORT = Number(process.env.PORT) || 3000;
const MODEL = process.env.CLAUDE_MODEL || "claude-opus-5-5";

const client = process.env.ANTHROPIC_API_KEY ? new Anthropic() : null;

// ---------- prompts and scenarios (plain files, easy to edit) ----------

const readPrompt = (name) => fs.readFile(path.join(here, "prompts", name), "utf8");

async function loadScenarios() {
  const dir = path.join(here, "scenarios");
  const files = (await fs.readdir(dir)).filter((f) => f.endsWith(".json")).sort();
  return Promise.all(
    files.map(async (f) => JSON.parse(await fs.readFile(path.join(dir, f), "utf8"))),
  );
}

// ---------- Claude calls ----------

const VERDICT_SCHEMA = {
  type: "object",
  properties: {
    verdict: { type: "string", enum: ["scam", "suspicious", "safe"] },
    headline: { type: "string" },
    why: { type: "string" },
    next_step: { type: "string" },
    learn_tip: { type: "string" },
  },
  required: ["verdict", "headline", "why", "next_step", "learn_tip"],
  additionalProperties: false,
};

const FEEDBACK_SCHEMA = {
  type: "object",
  properties: {
    score: { type: "string", enum: ["great", "okay", "risky"] },
    praise: { type: "string" },
    tip: { type: "string" },
    red_flags: { type: "array", items: { type: "string" } },
  },
  required: ["score", "praise", "tip", "red_flags"],
  additionalProperties: false,
};

class RefusalError extends Error {}

// One place for every Claude request. `schema` makes Claude answer as JSON.
async function askClaude({ system, messages, schema, effort = "low", maxTokens = 4000 }) {
  if (!client) throw new Error("NO_API_KEY");
  const response = await client.beta.messages.create({
    model: MODEL,
    max_tokens: maxTokens,
    system,
    messages,
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

// Turn the practice transcript into Claude messages: the scammer is "assistant".
// The conversation must start with a user turn, so the user "picks up" first.
const toClaudeMessages = (history) => [
  { role: "user", content: "(The phone rings. I pick up.) Hello?" },
  ...history.map((m) => ({
    role: m.from === "caller" ? "assistant" : "user",
    content: m.text,
  })),
];

// ---------- HTTP ----------

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
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
    if (raw.length > 100_000) throw new Error("TOO_LARGE");
  }
  return raw ? JSON.parse(raw) : {};
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
  if (err.message === "NO_API_KEY") {
    console.error("No ANTHROPIC_API_KEY. Put it in .env and restart (npm start).");
    return sendJson(res, 503, {
      error: "The assistant is not set up yet (API key missing).",
    });
  }
  if (err instanceof RefusalError) {
    return sendJson(res, 200, {
      error: "Sorry, I cannot help with that one. If in doubt: hang up and call the police yourself.",
    });
  }
  console.error(err);
  return sendJson(res, 502, {
    error: "That did not work just now. Please try again.",
  });
}

const routes = {
  // Check a described call or a pasted message.
  "POST /api/check": async (req, res) => {
    const { text } = await readJson(req);
    if (!text || !text.trim()) return sendJson(res, 400, { error: "Please type or say something first." });
    const result = await askClaude({
      system: await readPrompt("check.md"),
      messages: [{ role: "user", content: text.trim() }],
      schema: VERDICT_SCHEMA,
    });
    sendJson(res, 200, result);
  },

  // List practice scenarios (without the secret scammer script).
  "GET /api/scenarios": async (_req, res) => {
    const list = (await loadScenarios()).map(({ id, title, description, opening }) => ({
      id, title, description, opening,
    }));
    sendJson(res, 200, list);
  },

  // Practice: Claude plays the caller and answers the user's last line.
  "POST /api/practice": async (req, res) => {
    const { scenarioId, history = [] } = await readJson(req);
    const scenario = (await loadScenarios()).find((s) => s.id === scenarioId);
    if (!scenario) return sendJson(res, 404, { error: "Exercise not found." });
    const system = (await readPrompt("practice-caller.md")).replace(
      "{{SCENARIO}}",
      JSON.stringify(scenario, null, 2),
    );
    const reply = await askClaude({ system, messages: toClaudeMessages(history), maxTokens: 1000 });
    sendJson(res, 200, { reply });
  },

  // Practice: after hanging up, coach the user on how it went.
  "POST /api/feedback": async (req, res) => {
    const { scenarioId, history = [] } = await readJson(req);
    const scenario = (await loadScenarios()).find((s) => s.id === scenarioId);
    if (!scenario) return sendJson(res, 404, { error: "Exercise not found." });
    const transcript = history
      .map((m) => `${m.from === "caller" ? "Caller" : "User"}: ${m.text}`)
      .join("\n");
    const result = await askClaude({
      system: await readPrompt("practice-feedback.md"),
      messages: [
        {
          role: "user",
          content: `Scenario: ${scenario.title}\nTypical warning signs: ${scenario.red_flags.join("; ")}\n\nConversation:\n${transcript}`,
        },
      ],
      schema: FEEDBACK_SCHEMA,
    });
    sendJson(res, 200, result);
  },

  "GET /api/health": async (_req, res) => {
    sendJson(res, 200, { ok: true, apiKey: Boolean(client), model: MODEL });
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
  console.log(`Scam Shield running: http://localhost:${PORT}`);
  if (!client) console.log("Warning: no ANTHROPIC_API_KEY yet. The screen works, Claude calls will fail.");
});
