#!/usr/bin/env python3
"""Builds the character SVGs in this folder.

The SVG paths are hand-written below; this script only shares the parts that
repeat (Margaret's head and body, Agatha's mascot geometry) so every scene stays
on-model. Edit here and re-run `python3 build.py`, rather than editing the SVGs.

Group ids are stable so Remotion can animate them (rotate/translate a group, or
swap a variant). Pivot points for rotating arms are noted in comments as
data-pivot="x y" attributes in the group's own coordinate space.
"""
from pathlib import Path

OUT = Path(__file__).resolve().parent

# Palette
PURPLE = "#6B3FE0"
DPURPLE = "#3E1F99"
LAV = "#EFE6FF"
OFFW = "#FAF9F5"
INK = "#1E1B2E"
ORANGE = "#FF7A3D"
PEACH = "#FFF1E3"
MINT = "#E3F6F1"
GREEN = "#17694B"
PINK = "#FF9FB2"
YELLOW = "#FFB547"

# Margaret
M_SKIN, M_SKIN_SH, M_SKIN_LN = "#F2C6A5", "#E3AA86", "#C98466"
M_HAIR, M_HAIR_SH, M_HAIR_HI = "#E9E7EF", "#C9C4D4", "#FFFFFF"
CARDI, CARDI_SH, CARDI_HI = "#8F6EF0", PURPLE, "#A88CF5"
SLEEVE = "#7D59EE"  # arms a touch darker than the torso so they read in front of it
LIP = "#B4534F"

# Anna
A_SKIN, A_SKIN_SH, A_SKIN_LN = "#E5AB85", "#D19168", "#B0704D"
A_HAIR, A_HAIR_SH = "#3B2A2E", "#24191C"
BLAZER, BLAZER_SH = "#1F7A57", GREEN


def svg(viewbox, body, title):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{viewbox}" '
        f'role="img" aria-label="{title}">\n<title>{title}</title>\n{body}\n</svg>\n'
    )


# ---------------------------------------------------------------- Margaret

def margaret_head(eyes="open", brows="neutral", mouth="smile", look=(0, 0)):
    """Margaret's head in local coords: face centre (0,0), face ~72 wide."""
    lx, ly = look
    # eyes
    if eyes == "happy":
        eye_svg = (
            f'<path d="M-20 -2 Q-15 -7 -10 -2" stroke="{INK}" stroke-width="2.6" fill="none" stroke-linecap="round"/>'
            f'<path d="M10 -2 Q15 -7 20 -2" stroke="{INK}" stroke-width="2.6" fill="none" stroke-linecap="round"/>'
        )
    elif eyes == "down":
        eye_svg = (
            f'<path d="M-20 -3 Q-15 1 -10 -3" stroke="{INK}" stroke-width="2.6" fill="none" stroke-linecap="round"/>'
            f'<path d="M10 -3 Q15 1 20 -3" stroke="{INK}" stroke-width="2.6" fill="none" stroke-linecap="round"/>'
        )
    else:
        r = 4.2 if eyes == "wide" else 3.4
        eye_svg = (
            f'<ellipse cx="{-15 + lx}" cy="{-3 + ly}" rx="{r * 0.9:.1f}" ry="{r}" fill="{INK}"/>'
            f'<ellipse cx="{15 + lx}" cy="{-3 + ly}" rx="{r * 0.9:.1f}" ry="{r}" fill="{INK}"/>'
            f'<circle cx="{-13.8 + lx}" cy="{-4.4 + ly}" r="1.1" fill="#FFFFFF"/>'
            f'<circle cx="{16.2 + lx}" cy="{-4.4 + ly}" r="1.1" fill="#FFFFFF"/>'
        )
    # brows
    if brows == "raised":
        b = ("M-24 -22 Q-16 -29 -7 -25", "M7 -25 Q16 -29 24 -22")
    elif brows == "worried":
        b = ("M-24 -19 Q-16 -21 -8 -26", "M8 -26 Q16 -21 24 -19")
    else:
        b = ("M-24 -19 Q-16 -24 -7 -21", "M7 -21 Q16 -24 24 -19")
    brow_svg = "".join(
        f'<path d="{d}" stroke="#A39DB0" stroke-width="3.2" fill="none" stroke-linecap="round"/>' for d in b
    )
    # mouth
    if mouth == "open":
        mouth_svg = (
            f'<path d="M-10 19 Q0 18 10 19 Q9 32 0 32 Q-9 32 -10 19 Z" fill="#8E3B3B"/>'
            f'<path d="M-8.5 19.4 Q0 18.6 8.5 19.4 L8 22.5 Q0 23.5 -8 22.5 Z" fill="#FFFFFF"/>'
            f'<path d="M-5 29.5 Q0 26 5 29.5 Q0 32 -5 29.5 Z" fill="{PINK}"/>'
        )
    elif mouth == "worried":
        mouth_svg = f'<path d="M-8 26 Q0 21.5 8 26" stroke="{LIP}" stroke-width="3" fill="none" stroke-linecap="round"/>'
    else:
        mouth_svg = f'<path d="M-11 20 Q0 30 11 20 Q0 25 -11 20 Z" fill="{LIP}" stroke="{LIP}" stroke-width="1.5" stroke-linejoin="round"/>'

    return f'''
  <g id="margaret-hair-back"><path d="M-45 22 C-58 0 -55 -42 -24 -55 C-4 -63 26 -61 42 -45 C57 -29 57 4 46 22 C38 27 -36 27 -45 22 Z" fill="{M_HAIR_SH}"/></g>
  <g id="margaret-ears">
    <ellipse cx="-36" cy="3" rx="7" ry="9.5" fill="{M_SKIN_SH}"/>
    <ellipse cx="36" cy="3" rx="7" ry="9.5" fill="{M_SKIN_SH}"/>
    <circle cx="-37" cy="14" r="2.6" fill="#FFFFFF"/><circle cx="37" cy="14" r="2.6" fill="#FFFFFF"/>
  </g>
  <g id="margaret-face">
    <path d="M-35 -6 C-35 -34 -20 -46 0 -46 C20 -46 35 -34 35 -6 C35 22 20 42 0 42 C-20 42 -35 22 -35 -6 Z" fill="{M_SKIN}"/>
    <circle cx="-22" cy="13" r="6.5" fill="{PINK}" opacity="0.45"/>
    <circle cx="22" cy="13" r="6.5" fill="{PINK}" opacity="0.45"/>
    <path d="M-19 12 Q-22 20 -16 27" stroke="{M_SKIN_SH}" stroke-width="1.8" fill="none" stroke-linecap="round"/>
    <path d="M19 12 Q22 20 16 27" stroke="{M_SKIN_SH}" stroke-width="1.8" fill="none" stroke-linecap="round"/>
    <path d="M-1 3 Q-5 11 -1 13 Q2 14 4 12" stroke="{M_SKIN_LN}" stroke-width="2.4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
  </g>
  <g id="margaret-eyes">{eye_svg}</g>
  <g id="margaret-brows">{brow_svg}</g>
  <g id="margaret-glasses" fill="none" stroke="{DPURPLE}" stroke-width="2.4" stroke-linecap="round">
    <circle cx="-15" cy="-3" r="11.5" fill="#FFFFFF" fill-opacity="0.18"/>
    <circle cx="15" cy="-3" r="11.5" fill="#FFFFFF" fill-opacity="0.18"/>
    <path d="M-3.5 -4.5 Q0 -7.5 3.5 -4.5"/>
    <path d="M-26.5 -5 L-35 -7"/><path d="M26.5 -5 L35 -7"/>
  </g>
  <g id="margaret-mouth">{mouth_svg}</g>
  <g id="margaret-hair">
    <path d="M-42 4 C-50 -26 -36 -57 -2 -59 C32 -61 53 -37 44 4 C41 -10 38 -20 31 -28 C22 -23 8 -25 -3 -33 C-11 -27 -24 -25 -33 -27 C-37 -19 -40 -8 -42 4 Z" fill="{M_HAIR}"/>
    <path d="M-30 -40 Q-16 -52 2 -50" stroke="{M_HAIR_HI}" stroke-width="3" fill="none" stroke-linecap="round"/>
    <path d="M10 -48 Q26 -46 34 -34" stroke="{M_HAIR_HI}" stroke-width="3" fill="none" stroke-linecap="round"/>
    <path d="M-3 -33 Q6 -38 14 -40" stroke="{M_HAIR_SH}" stroke-width="2.2" fill="none" stroke-linecap="round"/>
  </g>'''


def margaret_neck():
    return f'<path d="M-12 26 L-12 62 Q0 70 12 62 L12 26 Z" fill="{M_SKIN_SH}"/>'


def margaret_torso(bottom=136):
    """Cardigan torso in head-local coords; neck sits at (0,40..62)."""
    return f'''
    <path d="M-84 {bottom} L-84 108 C-84 82 -64 68 -26 60 L26 60 C64 68 84 82 84 108 L84 {bottom} Z" fill="{CARDI}"/>
    <path d="M-22 58 Q0 72 22 58 L28 64 L0 100 L-28 64 Z" fill="{OFFW}"/>
    <path d="M-22 58 Q-10 66 0 68 L-6 78 Q-18 74 -26 64 Z M22 58 Q10 66 0 68 L6 78 Q18 74 26 64 Z" fill="#E6E1F0"/>
    <g fill="#FFFFFF">{''.join(f'<circle cx="{x}" cy="{y}" r="2.2"/>' for x, y in [(-12, 66), (-6, 69), (0, 70), (6, 69), (12, 66)])}</g>
    <path d="M-26 60 L0 100 L0 {bottom} L-10 {bottom} L-10 102 L-34 64 Z" fill="{CARDI_SH}" opacity="0.55"/>
    <path d="M26 60 L0 100 L0 {bottom} L10 {bottom} L10 102 L34 64 Z" fill="{CARDI_SH}" opacity="0.35"/>
    <circle cx="0" cy="110" r="3.2" fill="{LAV}"/><circle cx="0" cy="126" r="3.2" fill="{LAV}"/>
    <g id="margaret-brooch"><circle cx="-46" cy="86" r="4" fill="{ORANGE}"/><circle cx="-46" cy="86" r="1.6" fill="{YELLOW}"/></g>
    <path d="M-84 108 C-84 90 -76 78 -62 72" stroke="{CARDI_HI}" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.6"/>'''


def hand(cx, cy, rot=0, skin=M_SKIN, shade=M_SKIN_SH, scale=1.0):
    """Simple mitten hand with thumb, palm centred on (cx,cy), fingers pointing up at rot=0."""
    return f'''<g transform="translate({cx} {cy}) rotate({rot}) scale({scale})">
      <rect x="-9" y="-13" width="18" height="24" rx="9" fill="{skin}"/>
      <path d="M-3 -12 L-3 -4 M3 -12 L3 -4" stroke="{shade}" stroke-width="1.6" stroke-linecap="round"/>
      <ellipse cx="-9" cy="2" rx="4" ry="7" transform="rotate(25 -9 2)" fill="{skin}"/>
    </g>'''


def phone_back(x, y, w=32, h=58, rot=0):
    return f'''<g id="phone" transform="rotate({rot} {x + w / 2} {y + h / 2})">
      <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="7" fill="{INK}"/>
      <rect x="{x + 4}" y="{y + 4}" width="11" height="11" rx="3.5" fill="#3A3450"/>
      <circle cx="{x + 7.5}" cy="{y + 7.5}" r="2" fill="{INK}"/><circle cx="{x + 11.5}" cy="{y + 11.5}" r="2" fill="{INK}"/>
    </g>'''


def table(y_top=405):
    return f'''
  <g id="table">
    <rect x="96" y="{y_top + 120}" width="16" height="60" rx="6" fill="{DPURPLE}"/>
    <rect x="688" y="{y_top + 120}" width="16" height="60" rx="6" fill="{DPURPLE}"/>
    <path d="M86 {y_top} L714 {y_top} L748 {y_top + 42} L52 {y_top + 42} Z" fill="{MINT}"/>
    <path d="M52 {y_top + 42} L748 {y_top + 42} L748 {y_top + 118} Q700 {y_top + 132} 650 {y_top + 118} Q600 {y_top + 132} 550 {y_top + 118} Q500 {y_top + 132} 450 {y_top + 118} Q400 {y_top + 132} 350 {y_top + 118} Q300 {y_top + 132} 250 {y_top + 118} Q200 {y_top + 132} 150 {y_top + 118} Q100 {y_top + 132} 52 {y_top + 118} Z" fill="#BFE6DA"/>
    <path d="M52 {y_top + 42} L748 {y_top + 42}" stroke="#A8DCCC" stroke-width="4"/>
  </g>'''


def chair():
    return f'''
  <g id="chair">
    <rect x="262" y="228" width="276" height="200" rx="44" fill="{DPURPLE}"/>
    <rect x="286" y="250" width="228" height="170" rx="30" fill="#4E2BB0"/>
  </g>'''


def tea(x, y):
    return f'''
  <g id="tea" transform="translate({x} {y})">
    <g id="tea-steam" fill="none" stroke="#C9C4D4" stroke-width="3.5" stroke-linecap="round" opacity="0.9">
      <path d="M-8 -40 Q-14 -50 -8 -60 Q-2 -70 -8 -80"/>
      <path d="M8 -44 Q2 -54 8 -64 Q14 -74 8 -84"/>
    </g>
    <ellipse cx="0" cy="22" rx="42" ry="9" fill="{OFFW}"/>
    <ellipse cx="0" cy="22" rx="42" ry="9" fill="none" stroke="#D9D4E4" stroke-width="2"/>
    <path d="M24 -14 Q44 -14 42 2 Q40 14 22 12" stroke="{OFFW}" stroke-width="7" fill="none" stroke-linecap="round"/>
    <path d="M-28 -24 L28 -24 L24 10 Q22 20 0 20 Q-22 20 -24 10 Z" fill="{OFFW}"/>
    <path d="M-27 -12 L27 -12 L26 -4 L-26 -4 Z" fill="{ORANGE}"/>
    <ellipse cx="0" cy="-24" rx="28" ry="6" fill="#FFFFFF"/>
    <ellipse cx="0" cy="-23" rx="23" ry="4" fill="#B5713F"/>
  </g>'''


def pill_organiser(x, y):
    lids = []
    colors = [LAV, LAV, LAV, LAV, LAV, LAV, LAV]
    for i in range(7):
        cx = -84 + i * 24
        if i == 2:  # today's compartment open with pills
            lids.append(
                f'<rect x="{cx}" y="-16" width="20" height="16" rx="4" fill="{DPURPLE}"/>'
                f'<circle cx="{cx + 6}" cy="-7" r="3.4" fill="{PINK}"/><circle cx="{cx + 14}" cy="-8" r="3.4" fill="{YELLOW}"/>'
                f'<ellipse cx="{cx + 10}" cy="-3" rx="5" ry="2.6" fill="#FFFFFF"/>'
                f'<rect x="{cx}" y="-34" width="20" height="14" rx="4" fill="{colors[i]}" transform="rotate(-12 {cx} -20)"/>'
            )
        else:
            lids.append(f'<rect x="{cx}" y="-16" width="20" height="16" rx="4" fill="{colors[i]}"/>'
                        f'<circle cx="{cx + 10}" cy="-8" r="2.2" fill="{PURPLE}" opacity="0.35"/>')
    return f'''
  <g id="pill-organiser" transform="translate({x} {y})">
    <rect x="-92" y="-22" width="184" height="44" rx="10" fill="{PURPLE}"/>
    <rect x="-92" y="2" width="184" height="20" rx="8" fill="{DPURPLE}" opacity="0.5"/>
    {''.join(lids)}
  </g>'''


def margaret_at_table(head, arms, props_front, extra_back=""):
    return f'''
  {chair()}
  {extra_back}
  <g id="margaret-body" transform="translate(400 175) scale(1.25)">
    {margaret_neck()}
    {margaret_torso(bottom=200)}
  </g>
  <g id="margaret-head" transform="translate(400 175) scale(1.25)" data-pivot="0 40">{head}
  </g>
  {table()}
  {arms}
  {props_front}'''


def build_margaret():
    # 1. portrait
    portrait = svg("0 0 400 400", f'''
  <g id="margaret-body" transform="translate(200 158) scale(1.75)">
    {margaret_neck()}
    {margaret_torso(bottom=138)}
  </g>
  <g id="margaret-head" transform="translate(200 158) scale(1.75)" data-pivot="0 40">{margaret_head()}
  </g>''', "Margaret, portrait")
    (OUT / "margaret-portrait.svg").write_text(portrait)

    # 2. at the table with phone, tea and pill organiser
    arms = f'''
  <g id="margaret-arms" transform="translate(400 175) scale(1.25)">
    <g id="margaret-arm-right" data-pivot="-74 82">
      <path d="M-74 84 L-90 180 L-32 162" stroke="{SLEEVE}" stroke-width="30" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M-44 165 L-32 162" stroke="{CARDI_SH}" stroke-width="30" fill="none" stroke-linecap="round"/>
    </g>
    <g id="margaret-arm-left" data-pivot="74 82">
      <path d="M74 84 L90 180 L32 162" stroke="{SLEEVE}" stroke-width="30" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M44 165 L32 162" stroke="{CARDI_SH}" stroke-width="30" fill="none" stroke-linecap="round"/>
    </g>
    {phone_back(-17, 118, 34, 60, rot=0)}
    <g id="margaret-hands">
      {hand(-20, 152, rot=20)}
      {hand(20, 152, rot=-20)}
      <rect x="-19" y="138" width="9" height="20" rx="4.5" fill="{M_SKIN}"/>
      <rect x="10" y="138" width="9" height="20" rx="4.5" fill="{M_SKIN}"/>
    </g>
  </g>'''
    scene = margaret_at_table(
        margaret_head(eyes="down", mouth="smile"),
        arms,
        tea(615, 398) + pill_organiser(200, 432),
    )
    (OUT / "margaret-table.svg").write_text(svg("0 0 800 600", scene, "Margaret at the kitchen table with her phone"))

    # 3. phone call: phone at her ear, surprised-happy
    call = svg("0 0 500 500", f'''
  <g id="margaret-body" transform="translate(250 190) scale(1.6)">
    {margaret_neck()}
    {margaret_torso(bottom=196)}
  </g>
  <g id="margaret-head" transform="translate(250 190) scale(1.6)" data-pivot="0 40">{margaret_head(eyes="wide", brows="raised", mouth="open", look=(1, 0))}
  </g>
  <g id="margaret-arm-right" transform="translate(250 190) scale(1.6)" data-pivot="-76 86">
    <path d="M-76 86 L-80 150" stroke="{SLEEVE}" stroke-width="28" fill="none" stroke-linecap="round"/>
    <path d="M-78 152 L-52 40" stroke="{SLEEVE}" stroke-width="26" fill="none" stroke-linecap="round"/>
    <path d="M-56 52 L-52 40" stroke="{CARDI_SH}" stroke-width="27" fill="none" stroke-linecap="round"/>
    <g id="phone" transform="rotate(-8 -44 0)">
      <rect x="-53" y="-30" width="18" height="56" rx="5" fill="{INK}"/>
      <rect x="-50" y="-27" width="8" height="8" rx="2.5" fill="#3A3450"/>
    </g>
    <g id="margaret-hand-right">
      <rect x="-58" y="-2" width="22" height="32" rx="11" fill="{M_SKIN}"/>
      <path d="M-52 4 L-40 4 M-52 11 L-40 11 M-52 18 L-41 18" stroke="{M_SKIN_SH}" stroke-width="1.6" stroke-linecap="round"/>
      <ellipse cx="-38" cy="20" rx="4" ry="8" transform="rotate(-25 -38 20)" fill="{M_SKIN}"/>
    </g>
  </g>
  <g id="phone-ring" transform="translate(250 190) scale(1.6)" fill="none" stroke="{ORANGE}" stroke-width="3.2" stroke-linecap="round">
    <path d="M-64 -30 Q-72 -22 -68 -12"/>
    <path d="M-74 -38 Q-86 -24 -80 -8"/>
    <path d="M-84 -46 Q-100 -26 -92 -4"/>
  </g>''', "Margaret answering a call from Agatha")
    (OUT / "margaret-phone-call.svg").write_text(call)

    # 4. thinking over a pile of paperwork
    def sheet(x, y, w, h, rot, lines=4, fill="#FFFFFF"):
        ls = "".join(
            f'<rect x="{x + 10}" y="{y + 12 + i * 10}" width="{(w - 20) * (0.9 if i % 2 else 0.65):.0f}" height="3.2" rx="1.6" fill="#D9D4E4"/>'
            for i in range(lines)
        )
        return f'<g transform="rotate({rot} {x + w / 2} {y + h / 2})"><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="4" fill="{fill}"/>{ls}</g>'

    papers = f'''
  <g id="paper-pile">
    <g transform="translate(0 32)">
    <rect x="300" y="390" width="200" height="24" rx="6" fill="{LAV}"/>
    {sheet(312, 360, 150, 50, -4, 3)}
    {sheet(330, 352, 150, 50, 3, 3, fill=OFFW)}
    <g transform="rotate(-6 400 360)">
      <rect x="350" y="332" width="120" height="60" rx="5" fill="{PEACH}"/>
      <path d="M350 336 L410 368 L470 336" stroke="#F2D2B4" stroke-width="3" fill="none" stroke-linejoin="round"/>
      <rect x="448" y="338" width="16" height="18" rx="2" fill="{ORANGE}"/>
    </g>
    </g>
    {sheet(470, 404, 92, 64, 14, 4)}
    {sheet(240, 412, 96, 60, -12, 4, fill=OFFW)}
  </g>'''
    marks = f'''
  <g id="thinking-marks" fill="none" stroke="{PURPLE}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M538 92 C538 76 562 76 562 92 C562 102 550 103 550 114"/>
    <circle cx="550" cy="126" r="3" fill="{PURPLE}" stroke="none"/>
    <path d="M586 128 C586 118 601 118 601 128 C601 134 594 135 594 142" stroke-width="4"/>
    <circle cx="594" cy="150" r="2.4" fill="{PURPLE}" stroke="none"/>
  </g>'''
    arms = f'''
  <g id="margaret-arms" transform="translate(400 175) scale(1.25)">
    <g id="margaret-arm-right" data-pivot="-74 82">
      <path d="M-74 84 L-92 180 L-54 180" stroke="{SLEEVE}" stroke-width="30" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M-62 180 L-52 180" stroke="{CARDI_SH}" stroke-width="30" fill="none" stroke-linecap="round"/>
      {hand(-36, 180, rot=80)}
    </g>
    <g id="margaret-arm-left" data-pivot="74 82">
      <path d="M74 84 L72 186 L28 64" stroke="{SLEEVE}" stroke-width="28" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M32 76 L28 64" stroke="{CARDI_SH}" stroke-width="28" fill="none" stroke-linecap="round"/>
      <g id="margaret-hand-left">
        <path d="M12 50 Q12 30 24 26 Q36 28 36 46 Q35 60 25 60 Q14 60 12 50 Z" fill="{M_SKIN}"/>
        <path d="M17 36 Q24 32 31 37" stroke="{M_SKIN_SH}" stroke-width="1.6" fill="none" stroke-linecap="round"/>
      </g>
    </g>
  </g>'''
    scene = margaret_at_table(
        margaret_head(eyes="open", brows="worried", mouth="worried", look=(-1, 2)),
        arms,
        marks,
    )
    # papers sit on the table but under the resting arm: insert pile before arms
    scene = scene.replace(arms, papers + arms)
    (OUT / "margaret-thinking.svg").write_text(svg("0 0 800 600", scene, "Margaret looking worried at a pile of paperwork"))


# ---------------------------------------------------------------- Anna

def build_anna():
    head = f'''
  <g id="anna-bun"><circle cx="4" cy="-58" r="19" fill="{A_HAIR_SH}"/><path d="M-12 -52 Q4 -60 20 -50" stroke="{A_HAIR}" stroke-width="3" fill="none" stroke-linecap="round"/></g>
  <g id="anna-ears">
    <ellipse cx="-33" cy="3" rx="6.5" ry="9" fill="{A_SKIN_SH}"/><ellipse cx="33" cy="3" rx="6.5" ry="9" fill="{A_SKIN_SH}"/>
    <circle cx="-34" cy="12" r="2.4" fill="{YELLOW}"/><circle cx="34" cy="12" r="2.4" fill="{YELLOW}"/>
  </g>
  <g id="anna-face">
    <path d="M-32 -6 C-32 -34 -18 -46 0 -46 C18 -46 32 -34 32 -6 C32 22 18 43 0 45 C-18 43 -32 22 -32 -6 Z" fill="{A_SKIN}"/>
    <circle cx="-20" cy="13" r="6" fill="{PINK}" opacity="0.4"/><circle cx="20" cy="13" r="6" fill="{PINK}" opacity="0.4"/>
    <path d="M-1 3 Q-4 11 -1 13 Q2 14 4 12" stroke="{A_SKIN_LN}" stroke-width="2.4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
  </g>
  <g id="anna-eyes" stroke="{INK}" stroke-width="2.6" fill="none" stroke-linecap="round">
    <path d="M-20 -2 Q-14 3 -8 -2"/><path d="M8 -2 Q14 3 20 -2"/>
    <path d="M-20 -2 L-23 -4"/><path d="M20 -2 L23 -4"/>
  </g>
  <g id="anna-brows" stroke="{A_HAIR}" stroke-width="3.2" fill="none" stroke-linecap="round">
    <path d="M-22 -16 Q-15 -21 -7 -18"/><path d="M7 -18 Q15 -21 22 -16"/>
  </g>
  <g id="anna-mouth"><path d="M-10 21 Q0 30 10 21 Q0 25 -10 21 Z" fill="#A9483F" stroke="#A9483F" stroke-width="1.5" stroke-linejoin="round"/></g>
  <g id="anna-hair">
    <path d="M-37 6 C-41 -28 -24 -53 2 -53 C28 -53 42 -28 37 6 C35 -10 30 -22 20 -30 C10 -36 -6 -36 -16 -32 C-26 -26 -33 -12 -37 6 Z" fill="{A_HAIR}"/>
    <path d="M-16 -32 Q-2 -48 18 -44" stroke="{A_HAIR_SH}" stroke-width="2.4" fill="none" stroke-linecap="round"/>
    <path d="M-31 -10 Q-38 8 -30 22" stroke="{A_HAIR}" stroke-width="3" fill="none" stroke-linecap="round"/>
  </g>'''
    body = f'''
    <path d="M-11 26 L-11 62 Q0 70 11 62 L11 26 Z" fill="{A_SKIN_SH}"/>
    <path d="M-78 200 L-78 106 C-78 82 -60 68 -24 60 L24 60 C60 68 78 82 78 106 L78 200 Z" fill="{BLAZER}"/>
    <path d="M-22 60 Q0 74 22 60 L18 200 L-18 200 Z" fill="{OFFW}"/>
    <path d="M-24 60 L-6 120 L-20 124 L-34 84 L-26 78 L-36 70 Z" fill="{BLAZER_SH}"/>
    <path d="M24 60 L6 120 L20 124 L34 84 L26 78 L36 70 Z" fill="{BLAZER_SH}"/>
    <path d="M-64 74 C-74 82 -78 92 -78 106" stroke="#2E9470" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.7"/>'''
    arms = f'''
    <g id="anna-arm-right" data-pivot="-70 84">
      <path d="M-70 84 L-74 176 L-26 140" stroke="{BLAZER}" stroke-width="28" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M-36 148 L-26 140" stroke="{OFFW}" stroke-width="22" fill="none" stroke-linecap="round"/>
    </g>
    <g id="anna-arm-left" data-pivot="70 84">
      <path d="M70 84 L74 176 L26 140" stroke="{BLAZER}" stroke-width="28" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M36 148 L26 140" stroke="{OFFW}" stroke-width="22" fill="none" stroke-linecap="round"/>
    </g>
    {phone_back(-17, 104, 34, 60).replace('id="phone"', 'id="anna-phone"')}
    <g id="anna-hands">
      {hand(-19, 138, rot=30, skin=A_SKIN, shade=A_SKIN_SH)}
      {hand(19, 138, rot=-30, skin=A_SKIN, shade=A_SKIN_SH)}
    </g>'''
    note = f'''
  <g id="anna-notification" transform="translate(338 92)">
    <rect x="-62" y="-24" width="124" height="48" rx="16" fill="#FFFFFF"/>
    <path d="M-30 22 L-40 36 L-18 22 Z" fill="#FFFFFF"/>
    <circle cx="-34" cy="0" r="13" fill="{GREEN}"/>
    <path d="M-40 0 L-35.5 5 L-27 -5" stroke="#FFFFFF" stroke-width="3.2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
    <rect x="-14" y="-9" width="62" height="6" rx="3" fill="{LAV}"/>
    <rect x="-14" y="4" width="42" height="6" rx="3" fill="{MINT}"/>
  </g>'''
    out = svg("0 0 500 500", f'''
  <g id="anna-body" transform="translate(250 190) scale(1.6)">{body}
  </g>
  <g id="anna-head" transform="translate(250 190) scale(1.6)" data-pivot="0 40">{head}
  </g>
  <g id="anna-arms" transform="translate(250 190) scale(1.6)">{arms}
  </g>{note}''', "Anna, relieved, looking at her phone")
    (OUT / "anna-phone.svg").write_text(out)


# ---------------------------------------------------------------- Agatha
# Geometry copied from ios/CareCompanion/Assets.xcassets/AgathaMascot.imageset/AgathaMascot.svg
# (200x210 coordinate space). Only the eyes/mouth/arms/extras vary.

ORIG_EYES = '''<path d="M71 84 Q79 74 87 84" stroke="#CDB8FF" stroke-width="5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <path d="M113 84 Q121 74 129 84" stroke="#CDB8FF" stroke-width="5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>'''
OPEN_EYES = '''<ellipse cx="79" cy="81" rx="5" ry="6" fill="#CDB8FF"/><ellipse cx="121" cy="81" rx="5" ry="6" fill="#CDB8FF"/>
      <circle cx="81" cy="78.5" r="1.8" fill="#FFFFFF"/><circle cx="123" cy="78.5" r="1.8" fill="#FFFFFF"/>'''


def agatha(eyes, mouth, arm_l=0, arm_r=0, head_tilt=0, extras_back="", extras_front=""):
    return f'''
  <ellipse id="agatha-shadow" cx="100" cy="200" rx="46" ry="6" fill="#EFE6FF"/>
  {extras_back}
  <g id="agatha" >
    <g id="agatha-arm-left" transform="rotate({arm_l} 56 140)" data-pivot="56 140">
      <ellipse cx="44" cy="150" rx="11" ry="18" fill="#FFFFFF" stroke="#DDD0F5" stroke-width="2" transform="rotate(20 44 150)"/>
    </g>
    <g id="agatha-arm-right" transform="rotate({arm_r} 144 138)" data-pivot="144 138">
      <ellipse cx="158" cy="146" rx="11" ry="18" fill="#FFFFFF" stroke="#DDD0F5" stroke-width="2" transform="rotate(-28 158 146)"/>
    </g>
    <g id="agatha-body">
      <rect x="58" y="128" width="84" height="66" rx="30" fill="#FFFFFF" stroke="#DDD0F5" stroke-width="2"/>
      <path d="M66 140 L100 176 L134 140 L134 182 Q134 192 122 192 L78 192 Q66 192 66 182 Z" fill="#6B3FE0"/>
      <path d="M100 176 L100 192" stroke="#FFFFFF" stroke-width="2"/>
      <circle cx="93" cy="183" r="2.5" fill="#FFFFFF"/>
      <g id="agatha-bowtie">
        <path d="M88 132 L100 139 L88 146 Z M112 132 L100 139 L112 146 Z" fill="#FF7A3D"/>
        <circle cx="100" cy="139" r="3.5" fill="#E05E22"/>
      </g>
    </g>
    <g id="agatha-head" transform="rotate({head_tilt} 100 130)" data-pivot="100 130">
      <g id="agatha-antenna">
        <line x1="100" y1="30" x2="100" y2="14" stroke="#C9B8F0" stroke-width="4" stroke-linecap="round"/>
        <circle id="agatha-antenna-ball" cx="100" cy="11" r="7" fill="#FF7A3D"/>
      </g>
      <g id="agatha-ears"><circle cx="34" cy="80" r="11" fill="#DDD0F5"/><circle cx="166" cy="80" r="11" fill="#DDD0F5"/></g>
      <rect x="38" y="28" width="124" height="104" rx="50" fill="#FFFFFF" stroke="#DDD0F5" stroke-width="2"/>
      <rect id="agatha-visor" x="52" y="46" width="96" height="70" rx="32" fill="#2A2140"/>
      <g id="agatha-eyes">{eyes}</g>
      <g id="agatha-mouth">{mouth}</g>
      <g id="agatha-glasses">
        <circle cx="79" cy="81" r="16" fill="none" stroke="#FFB547" stroke-width="3.5"/>
        <circle cx="121" cy="81" r="16" fill="none" stroke="#FFB547" stroke-width="3.5"/>
        <path d="M95 80 Q100 75 105 80" stroke="#FFB547" stroke-width="3.5" fill="none" stroke-linecap="round"/>
        <path d="M63 79 L52 76" stroke="#FFB547" stroke-width="3.5" stroke-linecap="round"/>
        <path d="M137 79 L148 76" stroke="#FFB547" stroke-width="3.5" stroke-linecap="round"/>
      </g>
    </g>
  </g>
  {extras_front}'''


def build_agatha():
    vb = "-40 -10 280 222"
    speaking = agatha(
        ORIG_EYES,
        '<path d="M90 101 Q100 99.5 110 101 Q108.5 112 100 112 Q91.5 112 90 101 Z" fill="#CDB8FF"/>'
        '<path d="M94 108 Q100 105 106 108 Q100 111 94 108 Z" fill="#FF9FB2"/>',
        arm_l=55,
        extras_front=f'''<g id="agatha-soundwaves" fill="none" stroke="{PURPLE}" stroke-width="4" stroke-linecap="round">
    <path d="M176 64 Q184 80 176 96"/><path d="M190 54 Q202 80 190 106"/><path d="M204 44 Q220 80 204 116" opacity="0.6"/>
  </g>''',
    )
    (OUT / "agatha-speaking.svg").write_text(svg(vb, speaking, "Agatha speaking"))

    listening = agatha(
        OPEN_EYES,
        '<path d="M94 103 Q100 107 106 103" stroke="#CDB8FF" stroke-width="3.5" fill="none" stroke-linecap="round"/>',
        arm_r=-35,
        head_tilt=7,
        extras_front=f'''<g id="agatha-soundwaves" fill="none" stroke="{ORANGE}" stroke-width="4" stroke-linecap="round">
    <path d="M196 70 Q190 84 196 98"/><path d="M210 60 Q200 84 210 108"/><path d="M224 50 Q210 84 224 118" opacity="0.6"/>
  </g>''',
    )
    (OUT / "agatha-listening.svg").write_text(svg(vb, listening, "Agatha listening"))

    sparkle = lambda x, y, s, c: (
        f'<path transform="translate({x} {y}) scale({s})" d="M0 -10 Q1.5 -1.5 10 0 Q1.5 1.5 0 10 Q-1.5 1.5 -10 0 Q-1.5 -1.5 0 -10 Z" fill="{c}"/>'
    )
    happy = agatha(
        ORIG_EYES,
        '<path d="M86 99 Q100 98 114 99 Q112 114 100 114 Q88 114 86 99 Z" fill="#CDB8FF"/>'
        '<path d="M93 109 Q100 104 107 109 Q100 113.5 93 109 Z" fill="#FF9FB2"/>',
        arm_l=95,
        arm_r=-95,
        extras_front=f'<g id="agatha-sparkles">{sparkle(16, 40, 1.1, YELLOW)}{sparkle(186, 30, 1.3, ORANGE)}{sparkle(200, 92, 0.8, PINK)}{sparkle(0, 100, 0.8, PURPLE)}</g>',
    )
    (OUT / "agatha-happy.svg").write_text(svg(vb, happy, "Agatha happy"))


if __name__ == "__main__":
    build_margaret()
    build_anna()
    build_agatha()
    print("\n".join(sorted(p.name for p in OUT.glob("*.svg"))))
