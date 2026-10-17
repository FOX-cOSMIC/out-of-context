// Prints the scene/line timing table used in TIMELINE.md (node scripts/timeline-table.mjs).
import {readFileSync} from 'node:fs';
const src = readFileSync(new URL('../src/timeline.ts', import.meta.url), 'utf8');
const lines = JSON.parse(readFileSync(new URL('../src/generated/lines.json', import.meta.url), 'utf8'));
const dur = Object.fromEntries(lines.map((l) => [l.num, l]));
const fmt = (s) => `${Math.floor(s / 60)}:${(s % 60).toFixed(1).padStart(4, '0')}`;
let t = 0;
for (const m of src.matchAll(/\{id: '(\w+)', title: '([^']+)', seconds: ([\d.]+), lines: \[(.*?)\]\}/g)) {
  const [, id, title, secs, ls] = m;
  const end = t + Number(secs);
  console.log(`| ${id} | ${title} | ${fmt(t)} | ${fmt(end)} | ${secs} s |`);
  for (const lm of ls.matchAll(/num: '(\d+)', at: ([\d.]+)/g)) {
    const l = dur[lm[1]];
    console.log(`|  | line ${lm[1]} ${l.role} | ${fmt(t + Number(lm[2]))} | ${fmt(t + Number(lm[2]) + l.dur)} | ${l.dur} s |`);
  }
  t = end;
}
console.log(`\nTotal: ${t.toFixed(1)} s`);
