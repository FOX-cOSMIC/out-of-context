import React from 'react';
import {interpolate, useCurrentFrame} from 'remotion';
import {SceneShell} from '../components/SceneShell';
import {Graphic} from '../components/Graphic';
import {Phone} from '../components/Phone';
import {Chip, WordByWord} from '../components/Text';
import {pick} from '../assets';
import {scene, sec} from '../timeline';
import {C, bodyFont, headingFont} from '../theme';
import {Agatha, PHONE_H, PHONE_POS, PopIn, SC, TI} from './common';

const SKILLS = [
  {n: '1', t: 'Talk in your own words', at: 0.8},
  {n: '2', t: 'Show a photo', at: 2.4},
  {n: '3', t: 'Check the answer', at: 3.7},
];

// 1:43 Close: three AI skills, the pitch line, end card. Overlay: Claude Sonnet 5.5 · speech and voice on our own Mac.
export const Close: React.FC = () => {
  const s = scene('close');
  const f = useCurrentFrame();
  const [, l18] = s.lines;
  const endAt = l18.from + l18.frames + 4;
  const end = interpolate(f, [endAt, endAt + 14], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const endCard = pick([`${TI}end-card.svg`], TI, ['end']);
  return (
    <SceneShell scene={s} bg={pick([`${SC}bg-soft-gradient.svg`], SC, ['gradient'])} bgName="bg-soft-gradient.svg">
      <div style={{position: 'absolute', left: 90, top: 80, display: 'flex', gap: 28}}>
        {SKILLS.map((k) => (
          <PopIn key={k.n} from={sec(k.at)} style={{position: 'relative', width: 380, padding: '26px 24px', borderRadius: 28, background: C.white,
            border: `3px solid ${C.lavenderBorder}`, boxShadow: '0 12px 30px rgba(62,31,153,0.12)'}}>
            <div style={{width: 56, height: 56, borderRadius: '50%', background: C.purple, color: C.white, display: 'flex', alignItems: 'center',
              justifyContent: 'center', fontFamily: headingFont, fontWeight: 700, fontSize: 30}}>{k.n}</div>
            <div style={{fontFamily: headingFont, fontWeight: 700, fontSize: 38, color: C.ink, marginTop: 14}}>{k.t}</div>
          </PopIn>
        ))}
      </div>
      {f >= l18.from && (
        <div style={{position: 'absolute', left: 90, top: 380, width: 1250}}>
          <WordByWord text="Medicines are why they start." from={l18.from} every={5} style={{fontSize: 56, color: C.ink}} />
          <WordByWord text="AI skills are what they keep." from={l18.from + sec(2.2)} every={5} style={{fontSize: 56, color: C.ink, marginTop: 8}} highlight={['AI', 'skills']} />
        </div>
      )}
      <Agatha lines={s.lines} size={330} style={{left: 950, top: 600}} idle="happy" />
      <Phone height={PHONE_H} style={PHONE_POS} clips={[{file: '01-home.mp4', label: 'Home: big Agatha', from: 0, frames: s.frames, trimBefore: sec(2.5)}]} />
      <div style={{position: 'absolute', inset: 0, opacity: end, background: C.page}}>
        <Graphic path={endCard} name="end-card.svg" style={{width: 1920, height: 1080, border: 'none', borderRadius: 0}} />
        <div style={{position: 'absolute', left: 0, right: 0, bottom: 60, display: 'flex', justifyContent: 'center'}}>
          <Chip bg={C.white} color={C.inkSoft} style={{fontFamily: bodyFont, fontWeight: 400, fontSize: 28}}>Claude Sonnet 5.5 · speech and voice on our own Mac</Chip>
        </div>
      </div>
    </SceneShell>
  );
};
