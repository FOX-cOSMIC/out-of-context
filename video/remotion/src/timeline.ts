// The timing backbone. Each scene lists its voice lines with the second (inside the scene)
// where the line starts; line lengths come from video/voices/lines.json (measured audio).
// Change a scene's length or a line's start here; everything else follows.
import linesJson from './generated/lines.json';

export const FPS = 30;

export type Line = {num: string; scene: string; role: string; text: string; file: string; dur: number};
const LINES: Record<string, Line> = Object.fromEntries((linesJson as Line[]).map((l) => [l.num, l]));

export type PlacedLine = Line & {from: number; frames: number}; // frames relative to scene start
export type SceneDef = {id: string; title: string; seconds: number; lines: {num: string; at: number}[]};

export const SCENES: SceneDef[] = [
  {id: 'hook', title: 'Hook', seconds: 12.5, lines: [{num: '01', at: 0.8}, {num: '02', at: 9.0}]},
  {id: 'call', title: '09:00 call', seconds: 19.5, lines: [{num: '03', at: 2.6}, {num: '04', at: 11.6}, {num: '05', at: 14.5}]},
  {id: 'scan', title: 'Scan', seconds: 21.0, lines: [{num: '06', at: 0.6}, {num: '07', at: 8.2}, {num: '08', at: 15.4}]},
  {id: 'safety', title: 'Safety', seconds: 18.5, lines: [{num: '09', at: 0.7}, {num: '10', at: 4.4}, {num: '11', at: 12.0}, {num: '12', at: 14.6}]},
  {id: 'week', title: 'Week', seconds: 13.0, lines: [{num: '13', at: 0.7}, {num: '14', at: 4.0}]},
  {id: 'family', title: 'Family', seconds: 14.5, lines: [{num: '15', at: 0.7}, {num: '16', at: 10.0}]},
  {id: 'tech', title: 'How it works', seconds: 3.5, lines: []},
  {id: 'close', title: 'Close', seconds: 15.5, lines: [{num: '17', at: 0.7}, {num: '18', at: 6.3}]},
];

export const sec = (s: number) => Math.round(s * FPS);

export type Placed = {id: string; title: string; start: number; frames: number; lines: PlacedLine[]};
export const PLACED: Placed[] = (() => {
  let t = 0;
  return SCENES.map((s) => {
    const frames = sec(s.seconds);
    const lines = s.lines.map(({num, at}) => {
      const l = LINES[num];
      if (!l) throw new Error(`Line ${num} missing in lines.json`);
      return {...l, from: sec(at), frames: Math.ceil(l.dur * FPS)};
    });
    for (const l of lines) {
      if (l.from + l.frames > frames) throw new Error(`Line ${l.num} runs past the end of scene ${s.id}`);
    }
    const p = {id: s.id, title: s.title, start: t, frames, lines};
    t += frames;
    return p;
  });
})();

export const TOTAL_FRAMES = PLACED.reduce((a, s) => a + s.frames, 0);
export const scene = (id: string) => PLACED.find((s) => s.id === id)!;
