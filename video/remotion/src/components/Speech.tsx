import React from 'react';
import {Audio, Sequence, interpolate, staticFile, useCurrentFrame} from 'remotion';
import {has} from '../assets';
import type {PlacedLine} from '../timeline';
import {C, ROLE_STYLE, bodyFont, headingFont} from '../theme';

/** Every line's WAV at its time. */
export const SceneAudio: React.FC<{lines: PlacedLine[]}> = ({lines}) => (
  <>
    {lines.map((l) => {
      const path = `voices/${l.file}.wav`;
      return has(path) ? (
        <Sequence key={l.num} from={l.from} durationInFrames={l.frames + 2} layout="none">
          <Audio src={staticFile(path)} />
        </Sequence>
      ) : null;
    })}
  </>
);

/** 0..1 envelope while `role` is speaking at `f` (ramps in/out over a few frames). */
export const speakingEnv = (lines: PlacedLine[], role: string, f: number) => {
  let env = 0;
  for (const l of lines) {
    if (l.role !== role) continue;
    env = Math.max(env, Math.min(1, (f - l.from) / 5, (l.from + l.frames - f) / 5));
  }
  return Math.max(0, env);
};
export const useSpeaking = (lines: PlacedLine[], role: string) => speakingEnv(lines, role, useCurrentFrame());

/** Subtle bounce and scale on whoever is speaking. */
export const Speaker: React.FC<{lines: PlacedLine[]; role: string; children: React.ReactNode; style?: React.CSSProperties}> = ({lines, role, children, style}) => {
  const f = useCurrentFrame();
  const env = useSpeaking(lines, role);
  const scale = 1 + env * (0.02 + 0.02 * Math.sin(f * 0.9));
  const y = -env * 8 * Math.abs(Math.sin(f * 0.42));
  return <div style={{position: 'absolute', transform: `translateY(${y}px) scale(${scale})`, transformOrigin: '50% 90%', ...style}}>{children}</div>;
};

/** Subtitle pill at the bottom for the active line. */
export const Captions: React.FC<{lines: PlacedLine[]}> = ({lines}) => {
  const f = useCurrentFrame();
  const l = lines.find((x) => f >= x.from && f < x.from + x.frames + 8);
  if (!l) return null;
  const local = f - l.from;
  const end = l.frames + 8;
  const o = interpolate(local, [0, 6, end - 6, end], [0, 1, 1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const y = interpolate(local, [0, 8], [16, 0], {extrapolateRight: 'clamp'});
  const r = ROLE_STYLE[l.role] ?? ROLE_STYLE.NARRATOR;
  return (
    <div style={{position: 'absolute', left: 0, right: 0, bottom: 40, display: 'flex', justifyContent: 'center', opacity: o, transform: `translateY(${y}px)`}}>
      <div style={{display: 'flex', alignItems: 'center', gap: 20, maxWidth: 1560, padding: '16px 30px 16px 16px', borderRadius: 999,
        background: 'rgba(255,255,255,0.96)', boxShadow: '0 10px 30px rgba(30,27,46,0.18)', border: `2px solid ${C.lavenderBorder}`}}>
        <div style={{flexShrink: 0, fontFamily: headingFont, fontWeight: 700, fontSize: 26, color: r.color, background: r.bg,
          padding: '10px 20px', borderRadius: 999}}>{r.label}</div>
        <div style={{fontFamily: bodyFont, fontSize: 34, lineHeight: 1.25, color: C.ink}}>{l.text}</div>
      </div>
    </div>
  );
};
