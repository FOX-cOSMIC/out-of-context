import React from 'react';
import {interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {C, bodyFont, headingFont} from '../theme';

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

export const Typewriter: React.FC<{text: string; from?: number; cps?: number; style?: React.CSSProperties}> = ({text, from = 0, cps = 28, style}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const n = Math.floor(Math.max(0, f - from) * (cps / fps));
  const shown = text.slice(0, n);
  const caret = n < text.length && f >= from && Math.floor(f / 8) % 2 === 0;
  return <div style={{fontFamily: headingFont, fontWeight: 700, color: C.ink, ...style}}>{shown}<span style={{opacity: caret ? 1 : 0}}>|</span></div>;
};

export const WordByWord: React.FC<{text: string; from?: number; every?: number; style?: React.CSSProperties; highlight?: string[]}> = ({text, from = 0, every = 5, style, highlight = []}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  return (
    <div style={{fontFamily: headingFont, fontWeight: 700, color: C.ink, display: 'flex', flexWrap: 'wrap', columnGap: '0.28em', ...style}}>
      {text.split(' ').map((w, i) => {
        const s = spring({frame: f - from - i * every, fps, config: {damping: 14, stiffness: 160}});
        const hi = highlight.some((h) => w.toLowerCase().startsWith(h.toLowerCase()));
        return <span key={i} style={{opacity: s, transform: `translateY(${(1 - s) * 24}px)`, display: 'inline-block', color: hi ? C.purple : undefined}}>{w}</span>;
      })}
    </div>
  );
};

export const SlideUp: React.FC<{from?: number; children: React.ReactNode; style?: React.CSSProperties; until?: number}> = ({from = 0, until, children, style}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const s = spring({frame: f - from, fps, config: {damping: 15, stiffness: 120}});
  const out = until != null ? interpolate(f, [until - 8, until], [1, 0], clamp) : 1;
  return <div style={{opacity: s * out, transform: `translateY(${(1 - s) * 40}px)`, ...style}}>{children}</div>;
};

/** Small chip like "AI skill: show a photo". */
export const Chip: React.FC<{children: React.ReactNode; color?: string; bg?: string; style?: React.CSSProperties}> = ({children, color = C.purpleDeep, bg = C.lavender, style}) => (
  <div style={{display: 'inline-flex', alignItems: 'center', gap: 12, padding: '12px 24px', borderRadius: 999, background: bg, color,
    fontFamily: bodyFont, fontWeight: 700, fontSize: 30, border: `2px solid ${C.lavenderBorder}`, ...style}}>{children}</div>
);

/** Lower third: kicker + title, slides in from the left at `from`, out at `until`. */
export const LowerThird: React.FC<{kicker: string; title: string; from?: number; until?: number; accent?: string}> = ({kicker, title, from = 6, until, accent = C.purple}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const s = spring({frame: f - from, fps, config: {damping: 16, stiffness: 110}});
  const out = until != null ? interpolate(f, [until - 10, until], [1, 0], clamp) : 1;
  return (
    <div style={{position: 'absolute', left: 80, top: 64, opacity: s * out, transform: `translateX(${(1 - s) * -60}px)`, display: 'flex', alignItems: 'stretch', gap: 18}}>
      <div style={{width: 10, borderRadius: 6, background: accent}} />
      <div>
        <div style={{fontFamily: bodyFont, fontWeight: 700, fontSize: 24, letterSpacing: 2, textTransform: 'uppercase', color: accent}}>{kicker}</div>
        <div style={{fontFamily: headingFont, fontWeight: 700, fontSize: 46, color: C.ink}}>{title}</div>
      </div>
    </div>
  );
};
