import React from 'react';
import {interpolate, useCurrentFrame} from 'remotion';
import {SceneShell} from '../components/SceneShell';
import {Graphic} from '../components/Graphic';
import {Speaker} from '../components/Speech';
import {Phone} from '../components/Phone';
import {Chip, LowerThird} from '../components/Text';
import {pick} from '../assets';
import {scene, sec} from '../timeline';
import {C, bodyFont, headingFont} from '../theme';
import {CH, PHONE_H, PHONE_POS, PopIn, SC} from './common';

const STEPS = [
  {t: '09:00', label: 'Agatha calls', at: 1.4, color: C.purple},
  {t: '+10 min', label: 'tries again', at: 3.6, color: C.purple},
  {t: '+20 min', label: 'tries again', at: 4.8, color: C.purple},
  {t: '+30 min', label: 'Anna is told', at: 7.2, color: C.green},
];

// 1:26 When she doesn't confirm. Overlay: +10 min · +20 min · +30 min -> Anna is told.
export const Family: React.FC = () => {
  const s = scene('family');
  const f = useCurrentFrame();
  const [, l16] = s.lines;
  const line = interpolate(f, [sec(1.4), sec(7.2)], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  return (
    <SceneShell scene={s} bg={pick([`${SC}bg-soft-gradient.svg`], SC, ['gradient'])} bgName="bg-soft-gradient.svg">
      <LowerThird kicker="If she doesn't confirm" title="Later doesn't count" accent={C.green} />
      <div style={{position: 'absolute', left: 120, top: 250, width: 1140, height: 160}}>
        <div style={{position: 'absolute', left: 30, right: 30, top: 38, height: 8, borderRadius: 4, background: C.lavenderBorder}} />
        <div style={{position: 'absolute', left: 30, top: 38, height: 8, borderRadius: 4, background: C.purple, width: `${line * (1140 - 60)}px`}} />
        {STEPS.map((st, i) => (
          <PopIn key={i} from={sec(st.at)} style={{left: (i / (STEPS.length - 1)) * (1140 - 60) - 70 + 30, top: 0, width: 140, textAlign: 'center'}}>
            <div style={{width: 84, height: 84, margin: '0 auto', borderRadius: '50%', background: st.color, display: 'flex', alignItems: 'center',
              justifyContent: 'center', color: C.white, fontFamily: headingFont, fontWeight: 700, fontSize: 36, boxShadow: '0 8px 20px rgba(62,31,153,0.25)'}}>
              {i === STEPS.length - 1 ? '✓' : i + 1}
            </div>
            <div style={{fontFamily: headingFont, fontWeight: 700, fontSize: 32, color: C.ink, marginTop: 10}}>{st.t}</div>
            <div style={{fontFamily: bodyFont, fontSize: 24, color: C.inkSoft}}>{st.label}</div>
          </PopIn>
        ))}
      </div>
      <Speaker lines={s.lines} role="ANNA" style={{left: 140, top: 460, width: 420, height: 420}}>
        <Graphic path={pick([`${CH}anna-phone.svg`], CH, ['anna'])} name="anna-phone.svg" style={{width: '100%', height: '100%'}} />
      </Speaker>
      {f >= sec(7.6) && (
        <PopIn from={sec(7.2)} style={{left: 560, top: 470, width: 330, height: 220}}>
          <Graphic path={pick([`${SC}family-alert.svg`], SC, ['family'])} name="family-alert.svg" style={{width: '100%', height: '100%'}} />
        </PopIn>
      )}
      {f >= sec(7.6) && (
        <PopIn from={sec(7.6)} style={{left: 900, top: 480, width: 470}}>
          <div style={{padding: '22px 28px', borderRadius: 28, background: C.white, border: `3px solid ${C.green}`, boxShadow: '0 12px 30px rgba(30,27,46,0.15)'}}>
            <div style={{display: 'flex', alignItems: 'center', gap: 14}}>
              <div style={{fontFamily: headingFont, fontWeight: 700, fontSize: 30, color: C.green}}>Agatha → Anna</div>
              <Chip bg={C.peach} color={C.orangeDark} style={{fontSize: 20, padding: '4px 14px'}}>simulated</Chip>
            </div>
            <div style={{fontFamily: bodyFont, fontSize: 30, color: C.ink, marginTop: 8}}>Margaret hasn't confirmed her 09:00 pills.</div>
            {f >= l16.from && <div style={{fontFamily: bodyFont, fontSize: 30, color: C.purpleDeep, marginTop: 8}}><b>Anna:</b> Thanks, Agatha. I'll call Mum.</div>}
          </div>
        </PopIn>
      )}
      <Phone height={PHONE_H} style={PHONE_POS} clips={[{file: '09-family-call.mp4', label: 'Anna is told', from: 0, frames: s.frames, trimBefore: sec(2.5)}]} />
    </SceneShell>
  );
};
