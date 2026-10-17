import React from 'react';
import {interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {Graphic} from '../components/Graphic';
import {Speaker, speakingEnv} from '../components/Speech';
import {pick} from '../assets';
import type {PlacedLine} from '../timeline';

export const CH = 'graphics/characters/';
export const SC = 'graphics/scenes/';
export const TI = 'graphics/titles/';

export const PHONE_H = 800;
export const PHONE_POS: React.CSSProperties = {left: 1400, top: 56};

/** Agatha mascot: speaking expression + bounce while she talks, listening while others talk, happy otherwise. */
export const Agatha: React.FC<{lines: PlacedLine[]; size: number; style: React.CSSProperties; idle?: 'happy' | 'listening'}> = ({lines, size, style, idle = 'happy'}) => {
  const f = useCurrentFrame();
  const speaking = speakingEnv(lines, 'AGATHA', f) > 0;
  const margaretTalking = speakingEnv(lines, 'MARGARET', f) > 0 || speakingEnv(lines, 'ANNA', f) > 0;
  const mood = speaking ? 'speaking' : margaretTalking ? 'listening' : idle;
  const path = pick([`${CH}agatha-${mood}.svg`], CH, ['agatha']);
  const float = Math.sin(f / 18) * 6;
  return (
    <Speaker lines={lines} role="AGATHA" style={{...style, width: size, height: size * 0.8}}>
      <div style={{transform: `translateY(${float}px)`, width: '100%', height: '100%'}}>
        <Graphic path={path} name={`agatha-${mood}.svg`} style={{width: '100%', height: '100%'}} />
      </div>
    </Speaker>
  );
};

/** Pop-in entrance (spring scale) at frame `from`. */
export const PopIn: React.FC<{from?: number; children: React.ReactNode; style?: React.CSSProperties}> = ({from = 0, children, style}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const s = spring({frame: f - from, fps, config: {damping: 12, stiffness: 140}});
  return <div style={{position: 'absolute', opacity: Math.min(1, s * 1.5), transform: `scale(${0.6 + 0.4 * s})`, ...style}}>{children}</div>;
};

/** Phone slides in from the right at `from`. */
export const SlideInRight: React.FC<{from?: number; children: React.ReactNode}> = ({from = 0, children}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const s = spring({frame: f - from, fps, config: {damping: 18, stiffness: 90}});
  return <div style={{position: 'absolute', inset: 0, transform: `translateX(${(1 - s) * 700}px)`, opacity: interpolate(s, [0, 0.3], [0, 1])}}>{children}</div>;
};
