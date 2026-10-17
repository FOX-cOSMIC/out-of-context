import React from 'react';
import {AbsoluteFill, Series} from 'remotion';
import {PLACED} from './timeline';
import {Hook} from './scenes/Hook';
import {Call} from './scenes/Call';
import {Scan} from './scenes/Scan';
import {Safety} from './scenes/Safety';
import {Week} from './scenes/Week';
import {Family} from './scenes/Family';
import {Close} from './scenes/Close';
import {Tech} from './scenes/Tech';
import {C} from './theme';

const COMPONENTS: Record<string, React.FC> = {hook: Hook, call: Call, scan: Scan, safety: Safety, week: Week, family: Family, tech: Tech, close: Close};

export const AgathaDemo: React.FC = () => (
  <AbsoluteFill style={{background: C.page}}>
    <Series>
      {PLACED.map((s) => {
        const Comp = COMPONENTS[s.id];
        return (
          <Series.Sequence key={s.id} durationInFrames={s.frames} name={s.title}>
            <Comp />
          </Series.Sequence>
        );
      })}
    </Series>
  </AbsoluteFill>
);
