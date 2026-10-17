import React from 'react';
import {spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {SceneShell} from '../components/SceneShell';
import {Graphic} from '../components/Graphic';
import {pick} from '../assets';
import {scene} from '../timeline';
import {TI} from './common';

// 1:39 How it works (no voice): Claude Sonnet 5.5 with tools · speech + voice on our own Mac · data stays on the phone.
export const Tech: React.FC = () => {
  const s = scene('tech');
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const k = spring({frame: f, fps, config: {damping: 16, stiffness: 100}});
  return (
    <SceneShell scene={s}>
      <div style={{position: 'absolute', inset: 0, opacity: k, transform: `translateY(${(1 - k) * 50}px) scale(${0.96 + 0.04 * k})`}}>
        <Graphic path={pick([`${TI}tech-card.svg`], TI, ['tech'])} name="tech-card.svg" style={{width: 1920, height: 1080, border: 'none', borderRadius: 0}} />
      </div>
    </SceneShell>
  );
};
