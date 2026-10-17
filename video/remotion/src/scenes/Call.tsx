import React from 'react';
import {interpolate, useCurrentFrame} from "remotion";
import {SceneShell} from '../components/SceneShell';
import {Graphic} from '../components/Graphic';
import {Speaker} from '../components/Speech';
import {Phone} from '../components/Phone';
import {Chip, LowerThird, SlideUp, WordByWord} from '../components/Text';
import {pick} from '../assets';
import {scene, sec} from '../timeline';
import {C} from '../theme';
import {Agatha, CH, PHONE_H, PHONE_POS, PopIn, SC} from './common';

// 0:13 09:00 Agatha calls. Overlay: AI calls her. She doesn't have to open an app.
export const Call: React.FC = () => {
  const s = scene('call');
  const f = useCurrentFrame();
  const [l3, l4, l5] = s.lines;
  const ringing = f < l3.from;
  const clockO = interpolate(f, [l3.from + 20, l3.from + 35], [1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  return (
    <SceneShell scene={s} bg={pick([`${SC}bg-soft-gradient.svg`], SC, ['gradient'])} bgName="bg-soft-gradient.svg">
      <LowerThird kicker="09:00 · morning" title="Agatha calls" />
      <SlideUp from={sec(0.8)} style={{position: 'absolute', left: 90, top: 196, width: 1200}}>
        <WordByWord text="AI calls her." from={sec(0.8)} style={{fontSize: 72, color: C.purpleDeep}} />
        <WordByWord text="She doesn't have to open an app." from={sec(1.6)} every={4} style={{fontSize: 44, color: C.inkSoft, marginTop: 6}} highlight={[]} />
      </SlideUp>
      <Speaker lines={s.lines} role="MARGARET" style={{left: 90, top: 380, width: 500, height: 500}}>
        <Graphic path={pick([`${CH}margaret-phone-call.svg`], CH, ['margaret', 'call'])} name="margaret-phone-call.svg" style={{width: '100%', height: '100%'}} />
      </Speaker>
      <Agatha lines={s.lines} size={420} style={{left: 760, top: 470}} idle="happy" />
      {/* 09:00 alarm clock and the incoming-call badge while the phone rings */}
      <div style={{position: 'absolute', left: 600, top: 330, width: 240, height: 240, opacity: clockO,
        transform: `rotate(${ringing ? Math.sin(f * 1.3) * 6 : 0}deg)`}}>
        <Graphic path={pick([`${SC}clock-9am.svg`], SC, ['clock'])} name="clock-9am.svg" style={{width: '100%', height: '100%'}} />
      </div>
      <div style={{position: 'absolute', left: 1180, top: 90, width: 220, height: 220, opacity: clockO,
        transform: `scale(${1 + 0.06 * Math.sin(f * 0.5)})`}}>
        <Graphic path={pick([`${SC}incoming-call-badge.svg`], SC, ['incoming'])} name="incoming-call-badge.svg" style={{width: '100%', height: '100%'}} />
      </div>
      <Phone height={PHONE_H} style={PHONE_POS} clips={[
        // RECORDINGS.md: 02 rings from 5.8 s; 03 picks up at 8.6 s, use only 5.5-24.5 s
        {file: '02-call-ringing.mp4', label: 'Agatha is calling', from: 0, frames: l3.from, trimBefore: sec(5.0)},
        {file: '03-call-conversation.mp4', label: 'Call: confirm your pills', from: l3.from, frames: s.frames - l3.from, trimBefore: sec(8.0), trimAfter: sec(24.5)},
      ]} />
      <PopIn from={l5.from + 6} style={{left: 760, top: 400}}>
        <Chip bg={C.mint} color={C.green}>✓ Morning pills ticked off</Chip>
      </PopIn>
    </SceneShell>
  );
};
