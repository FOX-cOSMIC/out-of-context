"""Render the 2:00 Agatha demo video from the voiced lines in video/voices.

One slide per spoken line (app-style phone screen + caption), rendered with headless Chrome,
then stitched with ffmpeg. Audio lines are placed at their `at` time from video/voices/lines.json.

Run:  python3 video/render/build.py      ->  video/agatha-demo.mp4
"""
import html, json, subprocess, pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
VOICES = ROOT / "video" / "voices"
OUT = ROOT / "video" / "render" / "out"
OUT.mkdir(parents=True, exist_ok=True)
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TOTAL = 120.0

lines = json.load(open(VOICES / "lines.json"))
def secs(at):
    m, s = at.split(":"); return int(m) * 60 + int(s)

CSS = """
*{box-sizing:border-box;margin:0;padding:0}
body{width:1920px;height:1080px;background:#FAF9F5;font-family:-apple-system,'SF Pro Display',Helvetica,sans-serif;color:#1E1B2E;display:flex;align-items:center;overflow:hidden}
.left{flex:1;padding:0 90px 0 120px}
.tag{display:inline-block;background:#EFE6FF;color:#5B33C9;font-weight:700;font-size:28px;padding:10px 22px;border-radius:40px;margin-bottom:30px}
h1{font-size:76px;line-height:1.08;letter-spacing:-1px;margin-bottom:28px}
.cap{font-size:40px;line-height:1.35;color:#3E1F99;border-left:8px solid #6B3FE0;padding-left:28px;margin-top:20px}
.who{font-size:24px;font-weight:700;letter-spacing:2px;color:#A3400F;margin-bottom:8px;text-transform:uppercase}
.phone{width:470px;height:960px;border-radius:70px;background:#111;padding:16px;margin-right:160px;box-shadow:0 30px 80px rgba(62,31,153,.25)}
.scr{width:100%;height:100%;border-radius:56px;background:#FAF9F5;overflow:hidden;padding:70px 30px 30px;display:flex;flex-direction:column;gap:20px;font-size:26px}
.dark{background:linear-gradient(#2a1d5c,#120c29);color:#fff;align-items:center;text-align:center}
.mascot{width:150px;height:150px;border-radius:50%;background:radial-gradient(circle at 35% 35%,#9b7bff,#6B3FE0);display:flex;align-items:center;justify-content:center;color:#fff;font-size:72px;font-weight:800;margin:0 auto}
.card{background:#fff;border:2px solid #DDD0F5;border-radius:28px;padding:22px}
.row{display:flex;align-items:center;gap:14px;padding:10px 0;font-size:27px}
.tick{width:38px;height:38px;border-radius:50%;border:3px solid #CDB8FF;flex:none;display:flex;align-items:center;justify-content:center;font-size:24px;color:#fff}
.tick.on{background:#2E9E7E;border-color:#2E9E7E}
.btn{border-radius:40px;padding:22px;text-align:center;font-weight:700;font-size:28px}
.p{background:#6B3FE0;color:#fff}.g{background:#EFE6FF;color:#3E1F99}.r{background:#E5484D;color:#fff}
.bub{border-radius:26px;padding:18px 22px;max-width:88%;line-height:1.3}
.me{align-self:flex-end;background:#6B3FE0;color:#fff}.ag{background:#EFE6FF}
.new{background:#FFF1E3;border-color:#FF7A3D}
.small{font-size:20px;color:#5A5470}
"""

def phone(scene, step):
    m = '<div class="mascot">A</div>'
    if scene == "01-hook":
        return f'<div class="scr">{m}<div style="text-align:center;font-size:40px;font-weight:700">Good morning, Margaret</div><div class="card" style="background:#E3F6F1">☀️ Morning · 8:00<br><b>4 pills</b> with breakfast</div><div class="card" style="background:#FFF1E3">🌙 Evening · 18:30<br><b>1 pill</b> with dinner</div><div style="flex:1"></div><div class="btn p">🎙 Tap and talk to Agatha</div></div>'
    if scene == "02-call":
        on = step >= 2
        pills = ["Ramipril 5 mg", "Metformin 500 mg", "Pantoprazole 20 mg", "ASS 100 (aspirin)"]
        rows = "".join(f'<div class="row"><div class="tick {"on" if on else ""}">{"✓" if on else ""}</div>{p}</div>' for p in pills)
        head = "Call · 0:12" if step else "incoming call…"
        return f'<div class="scr dark">{m}<div style="font-size:44px;font-weight:700">Agatha</div><div class="small" style="color:#CDB8FF">{head} · Morning pills</div><div class="card" style="color:#1E1B2E;text-align:left;width:100%">{rows}</div><div style="flex:1"></div><div class="btn {"g" if on else "p"}" style="width:100%">{"All taken ✓" if on else "Slide to confirm →"}</div></div>'
    if scene == "03-scan":
        img = (ROOT / "public/samples/test/medicine-box-new-amlodipine.png").as_uri()
        card = '<div class="card new"><b>Here is what I read</b><div class="row">🆕 Amlodipine 5 mg</div><div class="small">New. Not on your plan yet.</div></div><div class="card"><div class="row"><div class="tick on">✓</div>Everything else matches</div></div><div style="display:flex;gap:12px"><div class="btn p" style="flex:1">Yes, right</div><div class="btn g" style="flex:1">No</div></div>' if step else ""
        return f'<div class="scr"><div style="font-size:36px;font-weight:700">Scan</div><img src="{img}" style="width:100%;border-radius:20px">{card}</div>'
    if scene == "04-safety":
        b = ['<div class="bub me">Can I skip my Metformin today?</div>',
             '<div class="bub ag">Please don\'t change anything on your own. Ask Dr Hoffmann or your pharmacist. Shall I note the question?</div>',
             '<div class="bub me">Yes, please.</div>',
             '<div class="bub ag">Done. It\'s in your notes for Dr Hoffmann. 📝</div>']
        return f'<div class="scr">{m}{"".join(b[:step + 1])}</div>'
    if scene == "05-memory":
        ring = '<div style="width:280px;height:280px;border-radius:50%;margin:20px auto;background:conic-gradient(#6B3FE0 0 95%,#EFE6FF 0);display:flex;align-items:center;justify-content:center"><div style="width:220px;height:220px;border-radius:50%;background:#FAF9F5;display:flex;align-items:center;justify-content:center;font-size:64px;font-weight:800">95%</div></div>' if step else ""
        return f'<div class="scr"><div style="font-size:36px;font-weight:700">My pills this week</div>{ring}<div class="bub me">How did I do this week?</div>' + ('<div class="bub ag">Well done, 95% of your doses. Your mornings were perfect.</div>' if step else "") + "</div>"
    if scene == "06-family":
        return '<div class="scr"><div style="font-size:36px;font-weight:700">Anna\'s phone</div><div class="small">simulated</div><div class="card new"><b>Agatha · Evening pills</b><br>Mum hasn\'t confirmed her 18:30 pills. I tried 3 times over 30 minutes.</div><div class="btn p">📞 Call Mum</div>' + ('<div class="bub me">Thanks, Agatha. I\'ll call Mum.</div>' if step else "") + '</div>'
    return f'<div class="scr" style="justify-content:center;text-align:center">{m}<div style="font-size:52px;font-weight:800">Agatha</div><div class="small" style="font-size:26px">Your friendly helper for medicines and paperwork</div><div class="card">🗣 Talk in your own words</div><div class="card">📷 Show a photo</div><div class="card">✅ Check the answer</div></div>'

TITLES = {"01-hook": ("The problem", "Margaret, 78.<br>Five medicines.<br>Never used AI."),
          "02-call": ("Pill reminder call", "Today, AI calls her."),
          "03-scan": ("Scan", "She shows Agatha the new box."),
          "04-safety": ("Safety first", "No medical advice. Ever."),
          "05-memory": ("My pills", "She can just ask."),
          "06-family": ("Family", "\"Later\" doesn't count."),
          "07-close": ("Built in one day with Claude", "Medicines are why they start.<br>AI skills are what they keep.")}

def slide(i, ln, step):
    tag, h = TITLES[ln["scene"]]
    who = {"NARRATOR": "", "AGATHA": "Agatha", "MARGARET": "Margaret", "ANNA": "Anna, her daughter"}[ln["role"]]
    who_html = f'<div class="who">{who}</div>' if who else ""
    foot = '<div class="small" style="margin-top:40px;font-size:26px">Native iPhone app · Claude Sonnet 5.5 · speech on the phone and our own Mac · Team Out of Context</div>' if ln["scene"] == "07-close" else ""
    doc = f'<html><head><meta charset="utf-8"><style>{CSS}</style></head><body><div class="left"><div class="tag">{tag}</div><h1>{h}</h1>{who_html}<div class="cap">{html.escape(ln["text"])}</div>{foot}</div><div class="phone">{phone(ln["scene"], step)}</div></body></html>'
    p = OUT / f"s{i:02d}.html"; p.write_text(doc)
    png = OUT / f"s{i:02d}.png"
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
                    f"--screenshot={png}", "--window-size=1920,1080", p.as_uri()], check=True, capture_output=True)
    return png

# one slide per line; `step` counts lines already seen in the same scene
starts, pngs, seen = [], [], {}
for i, ln in enumerate(lines):
    step = seen.get(ln["scene"], 0); seen[ln["scene"]] = step + 1
    starts.append(0.0 if i == 0 else secs(ln["at"]))
    pngs.append(slide(i, ln, step))

concat = OUT / "slides.txt"
with open(concat, "w") as f:
    for i, png in enumerate(pngs):
        end = starts[i + 1] if i + 1 < len(starts) else TOTAL
        f.write(f"file '{png}'\nduration {end - starts[i]:.2f}\n")
    f.write(f"file '{pngs[-1]}'\n")

cmd = ["ffmpeg", "-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", str(concat)]
for ln in lines:
    cmd += ["-i", str(VOICES / (ln["file"] + ".wav"))]
mix = "".join(f"[{k+1}:a]adelay={secs(ln['at'])*1000}|{secs(ln['at'])*1000}[a{k}];" for k, ln in enumerate(lines))
mix += "".join(f"[a{k}]" for k in range(len(lines))) + f"amix=inputs={len(lines)}:normalize=0,apad[aout]"
cmd += ["-filter_complex", mix, "-map", "0:v", "-map", "[aout]", "-t", str(TOTAL),
        "-vf", "fps=30,format=yuv420p", "-c:v", "libx264", "-preset", "fast", "-crf", "23", "-tune", "stillimage",
        "-c:a", "aac", "-b:a", "160k", str(ROOT / "video" / "agatha-demo.mp4")]
subprocess.run(cmd, check=True)
print("wrote video/agatha-demo.mp4")
