import React from 'react';
import {interpolate, useCurrentFrame} from 'remotion';
import {SceneShell} from '../components/SceneShell';
import {Phone} from '../components/Phone';
import {Graphic} from '../components/Graphic';
import {Chip, LowerThird, SlideUp, WordByWord} from '../components/Text';
import {pick} from '../assets';
import {scene, sec} from '../timeline';
import {C, headingFont, bodyFont} from '../theme';
import {Agatha, PHONE_H, PHONE_POS, PopIn, SC} from './common';

// 1:14 Evening: "How did I do this week?". Overlay: Answers from her own history and calendar.
export const Week: React.FC = () => {
  const s = scene('week');
  const f = useCurrentFrame();
  const [, l14] = s.lines;
  const pct = Math.round(interpolate(f, [l14.from + 10, l14.from + sec(2.4)], [0, 95], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'}));
  const R = 130;
  const circ = 2 * Math.PI * R;
  const histAt = sec(8.0);
  const calAt = sec(10.5);
  return (
    <SceneShell scene={s} bg={pick([`${SC}bg-soft-gradient.svg`], SC, ['gradient'])} bgName="bg-soft-gradient.svg" bgColor={C.lavender}>
      <div style={{position: 'absolute', inset: 0, background: 'rgba(62,31,153,0.10)'}} />
      <LowerThird kicker="Evening" title="How did I do this week?" />
      <Agatha lines={s.lines} size={400} style={{left: 110, top: 480}} idle="happy" />
      <PopIn from={l14.from + 4} style={{left: 640, top: 330, width: 320, height: 320}}>
        <svg width={320} height={320} viewBox="0 0 320 320">
          <circle cx={160} cy={160} r={R} fill={C.white} stroke={C.lavenderBorder} strokeWidth={26} />
          <circle cx={160} cy={160} r={R} fill="none" stroke={C.purple} strokeWidth={26} strokeLinecap="round"
            strokeDasharray={circ} strokeDashoffset={circ * (1 - pct / 100)} transform="rotate(-90 160 160)" />
        </svg>
        <div style={{position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center'}}>
          <div style={{fontFamily: headingFont, fontWeight: 700, fontSize: 84, color: C.purpleDeep}}>{pct}%</div>
          <div style={{fontFamily: bodyFont, fontSize: 26, color: C.inkSoft}}>doses this week</div>
        </div>
      </PopIn>
      <SlideUp from={l14.from + sec(3.4)} style={{position: 'absolute', left: 1000, top: 420}}>
        <Chip bg={C.mint} color={C.green}>Mornings: perfect</Chip>
      </SlideUp>
      {f >= histAt - 20 && (
        <div style={{position: 'absolute', left: 90, top: 200, width: 1250}}>
          <WordByWord text="Answers from her own history and calendar" from={histAt - 20} every={4} style={{fontSize: 52, color: C.purpleDeep}} highlight={['history', 'calendar']} />
        </div>
      )}
      <SlideUp from={histAt} style={{position: 'absolute', left: 560, top: 690, width: 760, height: 195}}>
        <Graphic path={pick([`${SC}calendar-week.svg`], SC, ['calendar', 'week'])} name="calendar-week.svg" style={{width: '100%', height: '100%'}} />
      </SlideUp>
      <Phone height={PHONE_H} style={PHONE_POS} clips={[
        {file: '06-week-summary.mp4', label: 'Week summary', from: 0, frames: histAt, trimBefore: sec(1.5), trimAfter: sec(20)},
        {file: '07-pills-history.mp4', label: 'Pills history', from: histAt, frames: calAt - histAt, trimBefore: sec(1.3)},
        {file: '08-calendar.mp4', label: 'Calendar', from: calAt, frames: s.frames - calAt, trimBefore: sec(2.5)},
      ]} />
    </SceneShell>
  );
};
