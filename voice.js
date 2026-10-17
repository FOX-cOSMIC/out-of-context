// Local voice, no paid service: this Mac does speech-to-text and text-to-speech.
// - Speech to text: whisper-cli (whisper.cpp) + ffmpeg   (brew install whisper-cpp ffmpeg)
// - Text to speech: Kokoro-82M via the local service in tts/ (`npm run tts`), natural voice;
//   if that service is not running, macOS `say` (built in). Both end as AAC .m4a via `afconvert`.
// Settings (optional, in .env): WHISPER_MODEL, WHISPER_LANG, SAY_VOICE, SAY_RATE, KOKORO_URL

import { execFile } from "node:child_process";
import { promisify } from "node:util";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";

const run = promisify(execFile);

const WHISPER_MODEL =
  process.env.WHISPER_MODEL ||
  path.join(os.homedir(), ".local/share/whisper/ggml-large-v3-turbo.bin");
const WHISPER_LANG = process.env.WHISPER_LANG || "en";
const SAY_VOICE = process.env.SAY_VOICE || "Samantha";
const SAY_RATE = process.env.SAY_RATE || "165"; // words per minute; a bit slower than default
const KOKORO_URL = process.env.KOKORO_URL || "http://127.0.0.1:3002";
const KOKORO_TIMEOUT_MS = 15000;

// Each request gets its own temp folder, removed afterwards.
async function withTempDir(fn) {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), "care-voice-"));
  try {
    return await fn(dir);
  } finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
}

// Recorded audio (webm, mp4/m4a, wav, ...) -> text
export async function transcribe(audioBuffer) {
  return withTempDir(async (dir) => {
    const input = path.join(dir, "input");
    const wav = path.join(dir, "speech.wav");
    await fs.writeFile(input, audioBuffer);
    // whisper.cpp wants 16 kHz mono WAV
    await run("ffmpeg", ["-y", "-loglevel", "error", "-i", input, "-ar", "16000", "-ac", "1", wav]);
    const { stdout } = await run(
      "whisper-cli",
      ["-m", WHISPER_MODEL, "-f", wav, "-l", WHISPER_LANG, "-nt", "-np", "-bs", "5", "-bo", "5"],
      { maxBuffer: 10 * 1024 * 1024 },
    );
    return dropSilenceFiller(stdout.replace(/\s+/g, " ").trim());
  });
}

// Whisper "hears" words in silence ("you", "Thank you.", "[Music]"). Treat those as nothing.
const SILENCE_FILLER = new Set(["you", "thank you", "thanks for watching", "bye", "blank_audio", "silence"]);
function dropSilenceFiller(text) {
  if (text.length < 2) return "";
  if (/^(\s*(\[[^\]]*\]|\([^)]*\)))+\s*$/.test(text)) return ""; // only [..] or (..) parts
  const bare = text.toLowerCase().replace(/[^\p{L}\p{N}_\s]/gu, "").replace(/\s+/g, " ").trim();
  return SILENCE_FILLER.has(bare) ? "" : text;
}

// Text -> spoken audio (AAC in .m4a, plays in browsers and on iPhone)
// `rate` (words per minute) is optional; the caller clamps it. Default: SAY_RATE.
// Tries the Kokoro service first; falls back to macOS `say` if it is off or fails.
export async function speak(text, rate) {
  return withTempDir(async (dir) => {
    const m4a = path.join(dir, "speech.m4a");
    const source = (await kokoroToFile(text, rate, dir)) || (await sayToFile(text, rate, dir));
    await run("afconvert", ["-f", "m4af", "-d", "aac", source, m4a]);
    return fs.readFile(m4a);
  });
}

// Words per minute -> Kokoro speed (165 -> 0.95, 140 -> 0.85, 120 -> 0.77, 220 -> 1.17)
function kokoroSpeed(rate) {
  const wpm = Number(rate || SAY_RATE) || 165;
  return Math.round((0.95 + (wpm - 165) * 0.004) * 100) / 100;
}

// Returns the path of a WAV file, or null if the Kokoro service is unavailable.
async function kokoroToFile(text, rate, dir) {
  try {
    const res = await fetch(`${KOKORO_URL}/speak`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text, speed: kokoroSpeed(rate) }),
      signal: AbortSignal.timeout(KOKORO_TIMEOUT_MS),
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const wav = path.join(dir, "speech.wav");
    await fs.writeFile(wav, Buffer.from(await res.arrayBuffer()));
    return wav;
  } catch (err) {
    if (err.cause?.code !== "ECONNREFUSED") console.warn(`Kokoro TTS failed, using say: ${err.message}`);
    return null;
  }
}

async function sayToFile(text, rate, dir) {
  const textFile = path.join(dir, "text.txt");
  const aiff = path.join(dir, "speech.aiff");
  await fs.writeFile(textFile, text);
  await run("say", ["-v", SAY_VOICE, "-r", String(rate || SAY_RATE), "-f", textFile, "-o", aiff]);
  return aiff;
}

export const voiceSettings = { WHISPER_MODEL, WHISPER_LANG, SAY_VOICE, SAY_RATE, KOKORO_URL };
