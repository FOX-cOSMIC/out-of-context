import React from 'react';
import {Img, staticFile} from 'remotion';
import {C, bodyFont} from '../theme';

/** Grey-lavender box with the asset name: shown when an optional asset does not exist yet. */
export const Placeholder: React.FC<{name: string; style?: React.CSSProperties; tint?: string}> = ({name, style, tint}) => (
  <div style={{
    display: 'flex', alignItems: 'center', justifyContent: 'center', textAlign: 'center',
    background: tint ?? C.lavender, border: `3px dashed ${C.lavenderRing}`, borderRadius: 24,
    color: C.purpleDeep, fontFamily: bodyFont, fontSize: 26, padding: 16, boxSizing: 'border-box', ...style,
  }}>{name}</div>
);

/** An SVG/PNG from public/ if it exists, otherwise a placeholder with its name. */
export const Graphic: React.FC<{path: string | null; name: string; style?: React.CSSProperties; fit?: 'contain' | 'cover'}> = ({path, name, style, fit = 'contain'}) =>
  path ? <Img src={staticFile(path)} style={{objectFit: fit, ...style}} /> : <Placeholder name={name} style={style} />;
