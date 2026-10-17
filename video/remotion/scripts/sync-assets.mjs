// Copies the inputs the video needs into public/ and writes src/generated/manifest.json,
// which tells the composition which optional assets exist (graphics and recordings are made
// by other people and may be missing; the video then shows a placeholder instead).
// Run: npm run sync-assets   (render and studio run it automatically)
import {cpSync, existsSync, mkdirSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import {dirname, join, relative} from 'node:path';
import {fileURLToPath} from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..');           // video/remotion
const video = join(root, '..');          // video/
const pub = join(root, 'public');
const gen = join(root, 'src', 'generated');

const sources = [
  ['voices/lines', 'voices/lines', (f) => f.endsWith('.wav')],
  ['graphics', 'graphics', (f) => f.endsWith('.svg') || f.endsWith('.png')],
  ['recordings', 'recordings', (f) => f.endsWith('.mp4') || f.endsWith('.mov')],
];

const files = [];
const walk = (dir) => readdirSync(dir).flatMap((n) => {
  const p = join(dir, n);
  return statSync(p).isDirectory() ? walk(p) : [p];
});

for (const [from, to, keep] of sources) {
  const src = join(video, from);
  const dst = join(pub, to);
  rmSync(dst, {recursive: true, force: true});   // only ever our own public/ subfolder
  if (!existsSync(src)) { console.log(`skip (missing): video/${from}`); continue; }
  for (const f of walk(src)) {
    if (!keep(f)) continue;
    const rel = relative(src, f);
    mkdirSync(dirname(join(dst, rel)), {recursive: true});
    cpSync(f, join(dst, rel));
    files.push(`${to}/${rel}`.split('\\').join('/'));
  }
}

// Video durations (seconds) via ffprobe, so a short recording can freeze on its last frame.
// A recording that ffprobe cannot read (still being written, broken) is left out, so the
// video shows its placeholder instead of failing the render.
const durations = {};
for (const f of files.filter((x) => x.startsWith('recordings/'))) {
  let d = 0;
  try {
    d = Number(execFileSync('ffprobe', ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', join(pub, f)], {stdio: ['ignore', 'pipe', 'ignore']}).toString().trim()) || 0;
  } catch { d = 0; }
  if (d > 0) durations[f] = d;
  else { console.log(`skip (unreadable): ${f}`); files.splice(files.indexOf(f), 1); rmSync(join(pub, f), {force: true}); }
}

// Phone frame: read the viewBox and the screen rect documented in a comment
// (looks for a comment mentioning "screen" with x / y / width|w / height|h / rx numbers).
let phone = null;
const phoneFile = join(pub, 'graphics/scenes/phone-frame.svg');
if (existsSync(phoneFile)) {
  const svg = readFileSync(phoneFile, 'utf8');
  const vb = svg.match(/viewBox="([\d.\s-]+)"/);
  const [,, vw, vh] = vb ? vb[1].trim().split(/\s+/).map(Number) : [0, 0, 0, 0];
  const comment = (svg.match(/<!--[\s\S]*?-->/g) || []).find((c) => /screen/i.test(c)) || '';
  const num = (re) => { const m = comment.match(re); return m ? Number(m[1]) : null; };
  const rect = {
    x: num(/\bx\s*[=:]\s*"?([\d.]+)/i),
    y: num(/\by\s*[=:]\s*"?([\d.]+)/i),
    w: num(/\b(?:width|w)\s*[=:]\s*"?([\d.]+)/i),
    h: num(/\b(?:height|h)\s*[=:]\s*"?([\d.]+)/i),
    rx: num(/\b(?:rx|radius|r)\s*[=:]\s*"?([\d.]+)/i),
  };
  phone = {vw, vh, screen: rect.x != null && rect.w ? rect : null, comment: comment.slice(0, 400)};
}

mkdirSync(gen, {recursive: true});
cpSync(join(video, 'voices/lines.json'), join(gen, 'lines.json'));
writeFileSync(join(gen, 'manifest.json'), JSON.stringify({files: files.sort(), durations, phone}, null, 1));
console.log(`synced ${files.length} files (${Object.keys(durations).length} recordings); phone frame: ${phone ? JSON.stringify(phone.screen) : 'missing'}`);
