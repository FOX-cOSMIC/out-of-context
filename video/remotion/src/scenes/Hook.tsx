import React from 'react';
import {interpolate, useCurrentFrame} from 'remotion';
import {SceneShell} from '../components/SceneShell';
import {Graphic} from '../components/Graphic';
import {Speaker} from '../components/Speech';
import {Phone} from '../components/Phone';
import {Chip, LowerThird, SlideUp, Typewriter} from '../components/Text';
import {pick} from '../assets';
import {scene, sec} from '../timeline';
import {C} from '../theme';
import {CH, PHONE_H, PHONE_POS, SC, SlideInRight} from './common';

// 0:00 Margaret's kitchen table. Overlay: Margaret, 78 · 5 medicines · never used AI.
export const Hook: React.FC = () => {
  const s = scene('hook');
  const f = useCurrentFrame();
  const l2 = s.lines[1].from;
  const drawerOut = interpolate(f, [l2 - 10, l2 + 5], [1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  return (
    <SceneShell scene={s} bg={pick([`${SC}bg-kitchen.svg`], SC, ['kitchen'])} bgName="bg-kitchen.svg" zoom>
      <LowerThird kicker="Meet" title="Margaret Weber" from={8} until={l2} />
      <Speaker lines={s.lines} role="MARGARET" style={{left: 90, top: 250, width: 820, height: 615}}>
        <Graphic path={pick([`${CH}margaret-table.svg`], CH, ['margaret', 'table'])} name="margaret-table.svg" style={{width: '100%', height: '100%'}} />
      </Speaker>
      <div style={{position: 'absolute', left: 1080, top: 300, width: 660, height: 550, opacity: drawerOut}}>
        <Graphic path={pick([`${SC}drawer-paperwork.svg`], SC, ['drawer'])} name="drawer-paperwork.svg" style={{width: '100%', height: '100%'}} />
      </div>
      <div style={{position: 'absolute', left: 90, top: 180, display: 'flex', gap: 18}}>
        <SlideUp from={sec(1.0)}><Chip>Margaret, 78</Chip></SlideUp>
        <SlideUp from={sec(2.6)}><Chip bg={C.peach} color={C.orangeDark}>5 medicines</Chip></SlideUp>
        <SlideUp from={sec(6.0)}><Chip bg={C.white} color={C.ink}>never used AI</Chip></SlideUp>
      </div>
      <SlideInRight from={l2 - 4}>
        <Phone height={PHONE_H} style={PHONE_POS} clips={[{file: '01-home.mp4', label: 'Home', from: 0, frames: s.frames, trimBefore: sec(2.5)}]} />
      </SlideInRight>
      {f >= l2 && (
        <div style={{position: 'absolute', left: 90, top: 150, width: 1200, padding: '28px 36px', borderRadius: 32,
          background: 'rgba(255,255,255,0.92)', boxShadow: '0 16px 40px rgba(62,31,153,0.15)'}}>
          <Typewriter text="Today, AI calls her." from={l2 + 2} cps={18} style={{fontSize: 84, color: C.purpleDeep}} />
        </div>
      )}
    </SceneShell>
  );
};
