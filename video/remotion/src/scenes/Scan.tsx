import React from 'react';
import {interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {SceneShell} from '../components/SceneShell';
import {Graphic} from '../components/Graphic';
import {Speaker} from '../components/Speech';
import {Phone} from '../components/Phone';
import {Chip, LowerThird, SlideUp, Typewriter} from '../components/Text';
import {pick} from '../assets';
import {scene, sec} from '../timeline';
import {C, bodyFont, headingFont} from '../theme';
import {Agatha, CH, PHONE_H, PHONE_POS, SC} from './common';

const PillBox: React.FC = () => (
  <div style={{width: 380, height: 220, borderRadius: 18, background: C.white, border: `3px solid ${C.lavenderBorder}`,
    boxShadow: '0 20px 40px rgba(30,27,46,0.15)', overflow: 'hidden'}}>
    <div style={{height: 54, background: C.orange}} />
    <div style={{padding: '18px 24px'}}>
      <div style={{fontFamily: headingFont, fontWeight: 700, fontSize: 44, color: C.ink}}>Amlodipine</div>
      <div style={{fontFamily: bodyFont, fontSize: 26, color: C.inkSoft}}>5 mg · 50 tablets</div>
    </div>
  </div>
);

// 0:33 A new box from the pharmacy. Overlay: AI skill: show a photo · AI skill: check the answer.
export const Scan: React.FC = () => {
  const s = scene('scan');
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const [, l7, l8] = s.lines;
  const boxSvg = pick([`${SC}medicine-box-amlodipine.svg`], SC, ['amlodipine']);
  const box = spring({frame: f - sec(1.6), fps, config: {damping: 14, stiffness: 90}});
  const boxToPhone = interpolate(f, [sec(5.0), sec(6.6)], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  return (
    <SceneShell scene={s} bg={pick([`${SC}bg-soft-gradient.svg`], SC, ['gradient'])} bgName="bg-soft-gradient.svg">
      <LowerThird kicker="12:00 · noon" title="A new box from the pharmacy" accent={C.orangeDark} />
      <Speaker lines={s.lines} role="MARGARET" style={{left: 70, top: 330, width: 560, height: 420}}>
        <Graphic path={pick([`${CH}margaret-table.svg`], CH, ['margaret', 'table'])} name="margaret-table.svg" style={{width: '100%', height: '100%'}} />
      </Speaker>
      <div style={{position: 'absolute', left: 600 + boxToPhone * 560, top: 330 - (1 - box) * 300 - boxToPhone * 40,
        opacity: box * (1 - boxToPhone * 0.85), transform: `rotate(${-6 + boxToPhone * 6}deg) scale(${1 - boxToPhone * 0.3})`}}>
        {boxSvg ? <Graphic path={boxSvg} name="medicine-box-amlodipine.svg" style={{width: 420, height: 373}} /> : <PillBox />}
      </div>
      <Agatha lines={s.lines} size={360} style={{left: 820, top: 540}} idle="listening" />
      <div style={{position: 'absolute', left: 90, top: 200, display: 'flex', flexDirection: 'column', gap: 16, alignItems: 'flex-start'}}>
        <SlideUp from={sec(5.4)}><Chip>AI skill: show a photo</Chip></SlideUp>
        <SlideUp from={l8.from}><Chip bg={C.mint} color={C.green}>✓ AI skill: check the answer</Chip></SlideUp>
      </div>
      {f >= l7.from && f < l8.from && (
        <SlideUp from={l7.from + 4} style={{position: 'absolute', left: 660, top: 220, padding: '18px 26px', borderRadius: 24, background: C.white,
          border: `3px solid ${C.purple}`, fontFamily: bodyFont, fontSize: 30, color: C.ink, width: 560, boxShadow: '0 12px 30px rgba(62,31,153,0.15)'}}>
          <div style={{fontFamily: headingFont, fontWeight: 700, fontSize: 32, color: C.purple, marginBottom: 6}}>Here is what I read</div>
          <div><b style={{color: C.orangeDark}}>New:</b> Amlodipine 5 mg</div>
          <div><b style={{color: C.green}}>Matches your plan:</b> everything else</div>
        </SlideUp>
      )}
      {f >= l8.from && (
        <div style={{position: 'absolute', left: 660, top: 230, width: 640}}>
          <Typewriter text="Her first AI lesson." from={l8.from + sec(2.0)} cps={20} style={{fontSize: 60, color: C.purpleDeep}} />
        </div>
      )}
      <Phone height={PHONE_H} style={PHONE_POS} clips={[{file: '04-scan.mp4', label: 'Scan a box', from: 0, frames: s.frames, trimBefore: sec(2.5), trimAfter: sec(35)}]} />
    </SceneShell>
  );
};
