import {loadFont as loadQuicksand} from '@remotion/google-fonts/Quicksand';
import {loadFont as loadAtkinson} from '@remotion/google-fonts/AtkinsonHyperlegible';

// Same palette as the app (ios/CareCompanion/Theme.swift, Palette).
export const C = {
  page: '#FAF9F5',
  white: '#FFFFFF',
  ink: '#1E1B2E',
  inkSoft: '#5A5470',
  purple: '#6B3FE0',
  purpleDark: '#5B33C9',
  purpleDeep: '#3E1F99',
  lavender: '#EFE6FF',
  lavenderLight: '#F3EEFB',
  lavenderBorder: '#DDD0F5',
  lavenderRing: '#CDB8FF',
  orange: '#FF7A3D',
  orangeDark: '#E0602A',
  peach: '#FFF1E3',
  mint: '#E3F6F1',
  green: '#17694B',
  yellow: '#FFB547',
  sosRed: '#C8283A',
};

export const {fontFamily: headingFont} = loadQuicksand('normal', {weights: ['500', '600', '700'], subsets: ['latin']});
export const {fontFamily: bodyFont} = loadAtkinson('normal', {weights: ['400', '700'], subsets: ['latin']});

export const ROLE_STYLE: Record<string, {label: string; color: string; bg: string}> = {
  NARRATOR: {label: 'Narrator', color: C.ink, bg: '#E9E6F0'},
  AGATHA: {label: 'Agatha', color: C.white, bg: C.purple},
  MARGARET: {label: 'Margaret', color: C.white, bg: C.orangeDark},
  ANNA: {label: 'Anna', color: C.white, bg: C.green},
};
