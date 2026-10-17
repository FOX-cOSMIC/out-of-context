import React from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame} from 'remotion';
import {Graphic} from './Graphic';
import {Captions, SceneAudio} from './Speech';
import type {Placed} from '../timeline';
import {C} from '../theme';

/** Background, fade in/out, voice audio and captions for one scene. */
export const SceneShell: React.FC<{scene: Placed; bg?: string | null; bgName?: string; bgColor?: string; children: React.ReactNode; zoom?: boolean}> = ({scene, bg, bgName, bgColor = C.page, children, zoom}) => {
  const f = useCurrentFrame();
  const durationInFrames = scene.frames;
  const fade = interpolate(f, [0, 10, durationInFrames - 10, durationInFrames], [0, 1, 1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const scale = zoom ? interpolate(f, [0, durationInFrames], [1, 1.06]) : 1;
  return (
    <AbsoluteFill style={{background: bgColor}}>
      <AbsoluteFill style={{opacity: fade}}>
        {(bg || bgName) && (
          <AbsoluteFill style={{transform: `scale(${scale})`}}>
            <Graphic path={bg ?? null} name={bgName ?? 'background'} style={{width: 1920, height: 1080, borderRadius: 0, border: 'none'}} fit="cover" />
          </AbsoluteFill>
        )}
        {children}
        <Captions lines={scene.lines} />
      </AbsoluteFill>
      <SceneAudio lines={scene.lines} />
    </AbsoluteFill>
  );
};
