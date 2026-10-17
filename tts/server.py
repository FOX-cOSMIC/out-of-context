# /// script
# requires-python = ">=3.10,<3.13"
# dependencies = [
#   "mlx-audio==0.5.9",
#   "misaki[en]==0.9.4",
#   "soundfile",
#   "en-core-web-sm @ https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl",
# ]
# ///
"""Local text-to-speech for Care Companion: Kokoro-82M on Apple Silicon (MLX).

Loads the model once, then serves:
  POST /speak  {"text": "...", "speed": 0.95}  -> audio/wav (24 kHz mono, 16-bit)
               optional "voice": "bm_george" picks another Kokoro voice for this request
               (used for the demo-video voices); without it the default voice is used.
  GET  /health                                 -> {"ok": true, ...}

Listens only on 127.0.0.1. Start with:  npm run tts   (or: uv run tts/server.py)
Settings (environment): KOKORO_VOICE (default bf_emma), KOKORO_PORT (default 3002).
Model weights download once to the Hugging Face cache (~/.cache/huggingface), not the repo.
"""

import io
import json
import os
import re
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import numpy as np
import soundfile as sf
from mlx_audio.tts.utils import load_model

MODEL_ID = "prince-canuma/Kokoro-82M"
VOICE = os.environ.get("KOKORO_VOICE", "bf_emma")  # b* = British, a* = American (e.g. af_heart)
PORT = int(os.environ.get("KOKORO_PORT", "3002"))
SAMPLE_RATE = 24000
LANG = "b" if VOICE.startswith("b") else "a"
VOICE_NAME = re.compile(r"^[ab][fm]_[a-z]+$")  # English Kokoro voices: af_/am_ (US), bf_/bm_ (UK)

print(f"Loading {MODEL_ID} ...", flush=True)
model = load_model(MODEL_ID)
lock = threading.Lock()  # one generation at a time; MLX is not thread-safe


def synthesize(text: str, speed: float, voice: str = VOICE) -> bytes:
    lang = LANG if voice == VOICE else ("b" if voice.startswith("b") else "a")
    with lock:
        chunks = [np.array(r.audio) for r in model.generate(text=text, voice=voice, speed=speed, lang_code=lang)]
    audio = np.concatenate(chunks) if chunks else np.zeros(1, dtype=np.float32)
    buf = io.BytesIO()
    sf.write(buf, audio, SAMPLE_RATE, format="WAV", subtype="PCM_16")
    return buf.getvalue()


# Warm-up: first call loads the voice, phonemizer and Metal kernels.
t = time.time()
synthesize("Hello, I am ready.", 1.0)
print(f"Warm-up done in {time.time() - t:.1f} s. Voice {VOICE}.", flush=True)


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body, ctype):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _json(self, code, obj):
        self._send(code, json.dumps(obj).encode(), "application/json")

    def do_GET(self):
        if self.path == "/health":
            return self._json(200, {"ok": True, "model": MODEL_ID, "voice": VOICE})
        self._json(404, {"error": "not found"})

    def do_POST(self):
        if self.path != "/speak":
            return self._json(404, {"error": "not found"})
        try:
            body = json.loads(self.rfile.read(int(self.headers.get("Content-Length") or 0)) or b"{}")
            text = str(body.get("text", "")).strip()[:4000]
            speed = min(max(float(body.get("speed", 1.0)), 0.5), 1.5)
            voice = str(body.get("voice") or VOICE).strip()
        except (ValueError, TypeError):
            return self._json(400, {"error": "bad JSON"})
        if not text:
            return self._json(400, {"error": "text is empty"})
        if voice != VOICE and not VOICE_NAME.match(voice):
            return self._json(400, {"error": f"unknown or unsupported voice: {voice}"})
        try:
            t = time.time()
            wav = synthesize(text, speed, voice)
            print(f"{len(text)} chars ({voice}) in {time.time() - t:.2f} s", flush=True)
            self._send(200, wav, "audio/wav")
        except Exception as e:  # keep the service alive; the Node side falls back to `say`
            print(f"error: {e}", flush=True)
            self._json(500, {"error": str(e)})

    def log_message(self, *args):
        pass


print(f"Kokoro TTS listening on http://127.0.0.1:{PORT}", flush=True)
ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
