import React from 'react';
import {useCurrentFrame} from 'remotion';
import {SceneShell} from '../components/SceneShell';
import {Graphic} from '../components/Graphic';
import {Speaker} from '../components/Speech';
import {Phone} from '../components/Phone';
import {LowerThird, SlideUp, WordByWord} from '../components/Text';
import {pick} from '../assets';
import {scene, sec} from '../timeline';
import {C, bodyFont, headingFont} from '../theme';
import {Agatha, CH, PHONE_H, PHONE_POS, SC} from './common';

// 0:55 Safety. Overlay: Never medical advice. Questions go to her doctor.
export const Safety: React.FC = () => {
  const s = scene('safety');
  const f = useCurrentFrame();
  const [, l10, , l12] = s.lines;
  return (
    <SceneShell scene={s} bg={pick([`${SC}bg-soft-gradient.svg`], SC, ['gradient'])} bgName="bg-soft-gradient.svg">
      <LowerThird kicker="Safety" title="Stays on topic, no medical advice" accent={C.sosRed} />
      <Speaker lines={s.lines} role="MARGARET" style={{left: 60, top: 380, width: 640, height: 480}}>
        <Graphic path={pick([`${CH}margaret-thinking.svg`], CH, ['margaret', 'think'])} name="margaret-thinking.svg" style={{width: '100%', height: '100%'}} />
      </Speaker>
      <Agatha lines={s.lines} size={380} style={{left: 820, top: 500}} idle="listening" />
      {f >= l10.from && (
        <div style={{position: 'absolute', left: 90, top: 200, width: 1250}}>
          <WordByWord text="Never medical advice." from={l10.from + 6} style={{fontSize: 68, color: C.purpleDeep}} />
          <WordByWord text="Questions go to her doctor." from={l10.from + 30} every={4} style={{fontSize: 44, color: C.inkSoft, marginTop: 4}} highlight={['doctor']} />
        </div>
      )}
      {f >= l12.from && (
        <SlideUp from={l12.from + 4} style={{position: 'absolute', left: 760, top: 360, width: 520, padding: '20px 26px', borderRadius: 24,
          background: C.peach, border: `3px solid ${C.orange}`, boxShadow: '0 12px 30px rgba(30,27,46,0.15)'}}>
          <div style={{fontFamily: headingFont, fontWeight: 700, fontSize: 30, color: C.orangeDark}}>Note for Dr Hoffmann</div>
          <div style={{fontFamily: bodyFont, fontSize: 30, color: C.ink, marginTop: 6}}>"Can I skip my Metformin today?"</div>
        </SlideUp>
      )}
      <Phone height={PHONE_H} style={PHONE_POS} clips={[{file: '05-safety-question.mp4', label: 'Ask a question', from: 0, frames: s.frames, trimBefore: sec(3.0), trimAfter: sec(20)}]} />
    </SceneShell>
  );
};
