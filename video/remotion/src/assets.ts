// Which optional assets exist (written by scripts/sync-assets.mjs). Graphics and recordings are
// produced by other people, so every lookup can come back null and the caller shows a placeholder.
import manifest from './generated/manifest.json';

type Manifest = {
  files: string[];
  durations: Record<string, number>;
  phone: null | {vw: number; vh: number; screen: null | {x: number | null; y: number | null; w: number | null; h: number | null; rx: number | null}};
};
const M = manifest as Manifest;

export const has = (path: string) => M.files.includes(path);

/** First exact candidate that exists, else the first file in `dir` whose name contains every keyword. */
export const pick = (candidates: string[], dir?: string, keywords: string[] = []): string | null => {
  for (const c of candidates) if (has(c)) return c;
  if (dir && keywords.length) {
    const hit = M.files.find((f) => f.startsWith(dir) && keywords.every((k) => f.slice(dir.length).toLowerCase().includes(k)));
    if (hit) return hit;
  }
  return null;
};

export const recording = (name: string) => (has(`recordings/${name}`) ? `recordings/${name}` : null);
export const recordingSeconds = (path: string) => M.durations[path] ?? 0;
export const phoneInfo = M.phone;
