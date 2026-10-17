import React from 'react';
import {Composition} from 'remotion';
import {AgathaDemo} from './Video';
import {FPS, TOTAL_FRAMES} from './timeline';

export const RemotionRoot: React.FC = () => (
  <Composition id="AgathaDemo" component={AgathaDemo} durationInFrames={TOTAL_FRAMES} fps={FPS} width={1920} height={1080} />
);
