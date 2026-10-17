import React from 'react';
import {Freeze, Img, OffthreadVideo, Sequence, staticFile} from 'remotion';
import {phoneInfo, pick, recording, recordingSeconds} from '../assets';
import {FPS} from '../timeline';
import {C, headingFont, bodyFont} from '../theme';

/** from/frames: slot in the scene. trimBefore/trimAfter: in/out points in the source file, in frames. */
export type Clip = {file: string; label: string; from: number; frames: number; trimBefore?: number; trimAfter?: number};

const SCREEN_RATIO = 1206 / 2622; // portrait iPhone recording

/** One recording segment, muted. Plays from its start (or trimBefore); if it is shorter than
 * the segment it freezes on its last frame. Missing file -> lavender screen with the label. */
const ClipScreen: React.FC<{clip: Clip}> = ({clip}) => {
  const src = recording(clip.file);
  if (!src) {
    return (
      <div style={{position: 'absolute', inset: 0, background: C.lavender, display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center', gap: 18, padding: 30, textAlign: 'center'}}>
        <div style={{fontFamily: headingFont, fontWeight: 700, fontSize: 40, color: C.purpleDeep}}>{clip.label}</div>
        <div style={{fontFamily: bodyFont, fontSize: 22, color: C.inkSoft}}>recordings/{clip.file}</div>
      </div>
    );
  }
  const trim = clip.trimBefore ?? 0;
  const total = Math.min(Math.floor(recordingSeconds(src) * FPS), clip.trimAfter ?? Infinity) - trim;
  const play = total > 2 ? Math.min(clip.frames, total - 1) : clip.frames;
  const style: React.CSSProperties = {position: 'absolute', inset: 0, width: '100%', height: '100%', objectFit: 'cover'};
  return (
    <>
      <Sequence durationInFrames={play} layout="none">
        <OffthreadVideo src={staticFile(src)} muted trimBefore={trim || undefined} style={style} />
      </Sequence>
      {play < clip.frames && (
        <Sequence from={play} layout="none">
          <Freeze frame={play - 1}>
            <OffthreadVideo src={staticFile(src)} muted trimBefore={trim || undefined} style={style} />
          </Freeze>
        </Sequence>
      )}
    </>
  );
};

/** iPhone with recordings on its screen. Uses graphics/scenes/phone-frame.svg (screen rect read
 * from its comment by sync-assets) when it exists, else a drawn CSS phone. `height` in px. */
export const Phone: React.FC<{clips: Clip[]; height: number; style?: React.CSSProperties}> = ({clips, height, style}) => {
  const frameSvg = pick(['graphics/scenes/phone-frame.svg']);
  const scr = phoneInfo?.screen;
  const useSvg = Boolean(frameSvg && phoneInfo && phoneInfo.vw && scr && scr.w && scr.h);
  let width: number;
  let screen: React.CSSProperties;
  if (useSvg) {
    const {vw, vh} = phoneInfo!;
    width = (height * vw) / vh;
    screen = {left: `${(scr!.x! / vw) * 100}%`, top: `${(scr!.y! / vh) * 100}%`, width: `${(scr!.w! / vw) * 100}%`,
      height: `${(scr!.h! / vh) * 100}%`, borderRadius: ((scr!.rx ?? 0) / vw) * width};
  } else {
    const bezel = height * 0.022;
    const sh = height - 2 * bezel;
    width = sh * SCREEN_RATIO + 2 * bezel;
    screen = {left: bezel, top: bezel, right: bezel, bottom: bezel, borderRadius: height * 0.06};
  }
  const body = (
    <>
      {!useSvg && <div style={{position: 'absolute', inset: 0, background: '#16131F', borderRadius: height * 0.075,
        boxShadow: '0 30px 60px rgba(62,31,153,0.25), inset 0 0 0 3px #3a3550'}} />}
      <div style={{position: 'absolute', overflow: 'hidden', background: C.white, ...screen}}>
        {clips.map((c) => (
          <Sequence key={c.file + c.from} from={c.from} durationInFrames={c.frames} layout="none">
            <ClipScreen clip={c} />
          </Sequence>
        ))}
      </div>
      {!useSvg && <div style={{position: 'absolute', left: '50%', top: height * 0.035, transform: 'translateX(-50%)',
        width: width * 0.3, height: height * 0.032, borderRadius: 999, background: '#16131F'}} />}
      {useSvg && <Img src={staticFile(frameSvg!)} style={{position: 'absolute', inset: 0, width: '100%', height: '100%'}} />}
    </>
  );
  return <div style={{position: 'absolute', width, height, ...style}}>{body}</div>;
};
