#!/usr/bin/env python3
"""Generate the demo-video voices from video/script.md with the local Kokoro service.

    python3 video/voices/generate.py            # every script line -> lines/, full-preview.m4a, index.html
    python3 video/voices/generate.py --samples  # candidate voices per role -> samples/, index.html

To change a voice: edit CAST below (one line per role), then run the first command again.
Needs: the Kokoro service (npm run tts, http://127.0.0.1:3002, with the optional "voice" field)
and ffmpeg/ffprobe. Standard library only.
"""

import html
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.request

# ---- the cast: role -> (Kokoro voice, speed). AGATHA must stay bf_emma at the app's speed. ----
CAST = {
    "NARRATOR": ("bm_george", 0.95),
    "MARGARET": ("bf_lily", 0.88),
    "ANNA": ("af_heart", 1.0),
    "AGATHA": ("bf_emma", 0.95),
}

# Candidate voices tried for each role (same sample line), shown on the listening page.
CANDIDATES = {
    "NARRATOR": [("bm_george", 0.95), ("bm_lewis", 0.95), ("bm_daniel", 0.95)],
    "MARGARET": [("bf_isabella", 0.88), ("bf_alice", 0.88), ("bf_lily", 0.88)],
    "ANNA": [("af_heart", 1.0), ("af_bella", 1.0), ("af_sarah", 1.0)],
}
SAMPLE_LINES = {
    "NARRATOR": "Margaret is seventy-eight, and she has never used AI. Today, AI calls her.",
    "MARGARET": "Yes, I took them. Can I skip my Metformin today?",
    "ANNA": "Thanks, Agatha. I'll call Mum straight after this meeting.",
}
BRIEF = {
    "NARRATOR": "Explains the idea · calm, warm, British",
    "MARGARET": "78, the user · gentle, a little slower",
    "ANNA": "Her daughter, 40s · warm, a bit busy",
    "AGATHA": "The app's voice · fixed to the app (bf_emma)",
}

TTS_URL = os.environ.get("KOKORO_URL", "http://127.0.0.1:3002") + "/speak"
HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(HERE, "..", "script.md")
GAP_S = 0.6


def read_script():
    rows = []
    for line in open(SCRIPT, encoding="utf-8"):
        m = re.match(r"^\|\s*(\d{2})\s*\|\s*([\w-]+)\s*\|\s*([A-Z]+)\s*\|\s*(.+?)\s*\|\s*([\d:]+)\s*\|\s*$", line)
        if m:
            num, scene, role, text, at = m.groups()
            rows.append({"num": num, "scene": scene, "role": role, "text": text, "at": at})
    if not rows:
        sys.exit("no lines found in script.md")
    unknown = {r["role"] for r in rows} - CAST.keys()
    if unknown:
        sys.exit(f"roles without a voice in CAST: {unknown}")
    return rows


def speak(text, voice, speed, wav_out):
    body = json.dumps({"text": text, "speed": speed, "voice": voice}).encode()
    req = urllib.request.Request(TTS_URL, body, {"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=120) as r, tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as raw:
        raw.write(r.read())
    try:
        normalise(raw.name, wav_out)
    finally:
        os.unlink(raw.name)
    m4a = wav_out[:-4] + ".m4a"
    run(["ffmpeg", "-y", "-v", "error", "-i", wav_out, "-c:a", "aac", "-b:a", "128k", m4a])
    return duration(wav_out)


def normalise(src, dst):
    """Loudness to -16 LUFS (EBU R128), 24 kHz mono 16-bit.

    Measure with loudnorm, then apply plain gain plus a peak limiter (-1.5 dBFS). Plain two-pass
    loudnorm leaves short, peaky clips (2-3 s) quieter because its true-peak ceiling wins."""
    p = subprocess.run(["ffmpeg", "-hide_banner", "-i", src, "-af", "loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json",
                        "-f", "null", "-"], capture_output=True, text=True, check=True)
    block = p.stderr[p.stderr.rindex("{"):]
    st = json.loads(block[:block.index("}") + 1])
    gain = -16.0 - float(st["input_i"])
    af = f"volume={gain:.2f}dB,alimiter=limit=0.84:attack=2:release=40:level=false"
    run(["ffmpeg", "-y", "-v", "error", "-i", src, "-af", af, "-ar", "24000", "-ac", "1", "-c:a", "pcm_s16le", dst])


def duration(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path],
                         capture_output=True, text=True, check=True).stdout
    return round(float(out), 2)


def run(cmd):
    subprocess.run(cmd, check=True)


def make_lines(rows):
    os.makedirs(os.path.join(HERE, "lines"), exist_ok=True)
    for r in rows:
        voice, speed = CAST[r["role"]]
        r["file"] = f"lines/{r['num']}-{r['scene']}-{r['role'].lower()}"
        r["dur"] = speak(r["text"], voice, speed, os.path.join(HERE, r["file"] + ".wav"))
        print(f"{r['file']}.wav  {r['dur']:5.2f} s  {voice}@{speed}  {r['text'][:50]}")
    # full preview: every line with a 0.6 s gap
    silence = os.path.join(tempfile.gettempdir(), "agatha-gap.wav")
    run(["ffmpeg", "-y", "-v", "error", "-f", "lavfi", "-i", "anullsrc=r=24000:cl=mono", "-t", str(GAP_S),
         "-c:a", "pcm_s16le", silence])
    with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False) as lst:
        for i, r in enumerate(rows):
            if i:
                lst.write(f"file '{silence}'\n")
            lst.write(f"file '{os.path.join(HERE, r['file'] + '.wav')}'\n")
    run(["ffmpeg", "-y", "-v", "error", "-f", "concat", "-safe", "0", "-i", lst.name, "-c:a", "aac", "-b:a", "128k",
         os.path.join(HERE, "full-preview.m4a")])
    os.unlink(lst.name)
    os.unlink(silence)
    json.dump(rows, open(os.path.join(HERE, "lines.json"), "w"), indent=1)
    total = sum(r["dur"] for r in rows)
    print(f"total speech {total:.1f} s, preview {duration(os.path.join(HERE, 'full-preview.m4a')):.1f} s")


def make_samples():
    os.makedirs(os.path.join(HERE, "samples"), exist_ok=True)
    for role, cands in CANDIDATES.items():
        for voice, speed in cands:
            out = os.path.join(HERE, "samples", f"{role.lower()}-{voice}.wav")
            print(f"samples/{role.lower()}-{voice}.wav  {speak(SAMPLE_LINES[role], voice, speed, out):.2f} s")


def write_page():
    rows = json.load(open(os.path.join(HERE, "lines.json"))) if os.path.exists(os.path.join(HERE, "lines.json")) else []
    total = sum(r["dur"] for r in rows)
    e = html.escape
    cast_rows = []
    for role, (voice, speed) in CAST.items():
        cands = []
        for v, s in CANDIDATES.get(role, []):
            f = f"samples/{role.lower()}-{v}.m4a"
            if os.path.exists(os.path.join(HERE, f)):
                pick = " pick" if v == voice else ""
                cands.append(f'<div class="cand{pick}"><span>{e(v)} · {s}{" · chosen" if pick else ""}</span>'
                             f'<audio controls preload="none" src="{f}"></audio></div>')
        if not cands:
            cands.append('<p class="muted small">Fixed: the same voice the app uses.</p>')
        cast_rows.append(f'<tr><td data-l="Role"><span class="who {role.lower()}">{role}</span><div class="muted small">'
                         f'{e(BRIEF.get(role, ""))}</div></td><td data-l="Voice"><code>{e(voice)}</code> · speed {speed}'
                         f'</td><td data-l="Candidates">{"".join(cands)}</td></tr>')
    line_items = []
    for r in rows:
        line_items.append(f'<li><div class="meta"><span class="num">{r["num"]}</span><span class="who {r["role"].lower()}">'
                          f'{r["role"]}</span><span class="muted small">{e(r["scene"])} · at {r["at"]} · {r["dur"]:.1f} s</span>'
                          f'</div><p class="text">{e(r["text"])}</p><audio controls preload="none" src="{r["file"]}.m4a"></audio></li>')
    page = TEMPLATE.replace("{{CAST}}", "\n".join(cast_rows)).replace("{{LINES}}", "\n".join(line_items))
    page = page.replace("{{TOTAL}}", f"{total:.1f}").replace("{{COUNT}}", str(len(rows)))
    open(os.path.join(HERE, "index.html"), "w", encoding="utf-8").write(page)
    print("wrote index.html")


TEMPLATE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Agatha Voices</title>
<style>
:root{--bg:#FAF9F5;--surface:#FFFFFF;--surface-2:#EFE6FF;--text:#1E1B2E;--muted:#5D5873;--line:#E4DFEE;
 --accent:#6B3FE0;--accent-text:#5530C4;--n-bg:#E6E3EF;--n-fg:#3D3852;--m-bg:#FFE7DA;--m-fg:#8E3A0E;
 --a-bg:#EFE6FF;--a-fg:#4B2BB0;--an-bg:#DDF3EA;--an-fg:#1D6B4F;color-scheme:light}
@media (prefers-color-scheme: dark){:root:not([data-theme="light"]){--bg:#15131F;--surface:#1F1C2C;--surface-2:#2A2340;
 --text:#F1EEF8;--muted:#B4AECB;--line:#342F47;--accent:#9C7BFF;--accent-text:#B9A2FF;--n-bg:#2C293A;--n-fg:#D6D1E8;
 --m-bg:#47261A;--m-fg:#FFB48D;--a-bg:#2F2550;--a-fg:#C9B6FF;--an-bg:#173B30;--an-fg:#8FE0BF;color-scheme:dark}}
:root[data-theme="dark"]{--bg:#15131F;--surface:#1F1C2C;--surface-2:#2A2340;--text:#F1EEF8;--muted:#B4AECB;--line:#342F47;
 --accent:#9C7BFF;--accent-text:#B9A2FF;--n-bg:#2C293A;--n-fg:#D6D1E8;--m-bg:#47261A;--m-fg:#FFB48D;--a-bg:#2F2550;
 --a-fg:#C9B6FF;--an-bg:#173B30;--an-fg:#8FE0BF;color-scheme:dark}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--text);font:16px/1.5 system-ui,-apple-system,sans-serif;overflow-x:hidden}
.wrap{max-width:900px;margin:0 auto;padding:28px 16px 48px}
h1{font-size:2rem;margin:0 0 4px}h2{font-size:1.25rem;margin:32px 0 10px}
.muted{color:var(--muted)}.small{font-size:.85rem}
.note{background:var(--surface-2);border-radius:12px;padding:12px 14px;margin:14px 0}
code{font-family:ui-monospace,Menlo,monospace;font-size:.88em;background:var(--surface-2);padding:1px 6px;border-radius:6px;overflow-wrap:anywhere}
.tbl{width:100%;border-collapse:collapse;background:var(--surface);border:1px solid var(--line);border-radius:14px;overflow:hidden}
.tbl th,.tbl td{text-align:left;padding:10px 12px;border-bottom:1px solid var(--line);vertical-align:top}
.tbl th{font-size:.75rem;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);background:var(--surface-2)}
.tbl tr:last-child td{border-bottom:0}
.cand{margin:0 0 8px}.cand span{display:block;font-size:.82rem;color:var(--muted)}
.cand.pick span{color:var(--accent-text);font-weight:700}
audio{width:100%;max-width:340px;height:36px;display:block}
.who{display:inline-block;font-size:.72rem;font-weight:700;padding:1px 8px;border-radius:99px;letter-spacing:.03em}
.who.narrator{background:var(--n-bg);color:var(--n-fg)}.who.margaret{background:var(--m-bg);color:var(--m-fg)}
.who.agatha{background:var(--a-bg);color:var(--a-fg)}.who.anna{background:var(--an-bg);color:var(--an-fg)}
ol{list-style:none;margin:0;padding:0}
li{background:var(--surface);border:1px solid var(--line);border-radius:14px;padding:12px 14px;margin-bottom:10px}
.meta{display:flex;gap:8px;align-items:center;flex-wrap:wrap}
.num{font-weight:700;color:var(--accent-text);font-variant-numeric:tabular-nums}
.text{margin:6px 0 8px;font-size:1.05rem}
@media (max-width:640px){.tbl thead{display:none}.tbl,.tbl tbody,.tbl tr,.tbl td{display:block;width:100%}
 .tbl tr{border-bottom:1px solid var(--line);padding:6px 0}.tbl td{border:0;padding:4px 12px}
 .tbl td[data-l]::before{content:attr(data-l);display:block;font-weight:700;color:var(--muted);font-size:.75rem;text-transform:uppercase}}
</style>
</head>
<body>
<div class="wrap">
<h1>Agatha Voices</h1>
<p class="muted">Demo video "A day with Margaret" · team Out of Context · {{COUNT}} lines, {{TOTAL}} s of speech · Kokoro-82M on this Mac, -16 LUFS, 24 kHz.</p>
<div class="note small"><b>Change a voice:</b> edit one line in <code>CAST</code> at the top of <code>video/voices/generate.py</code>
(e.g. <code>"MARGARET": ("bf_lily", 0.88)</code>), then run <code>python3 video/voices/generate.py</code>. Text lives in
<code>video/script.md</code>. Needs the Kokoro service (<code>npm run tts</code>). Agatha stays <code>bf_emma</code>.</div>
<p><b>Full preview</b> (all lines, 0.6 s gaps)</p>
<audio controls preload="none" src="full-preview.m4a"></audio>
<h2>Cast</h2>
<table class="tbl"><thead><tr><th>Role</th><th>Voice</th><th>Candidates (same sample line)</th></tr></thead>
<tbody>
{{CAST}}
</tbody></table>
<h2>Lines</h2>
<ol>
{{LINES}}
</ol>
</div>
</body>
</html>
"""

if __name__ == "__main__":
    if "--samples" in sys.argv:
        make_samples()
    else:
        make_lines(read_script())
    write_page()
