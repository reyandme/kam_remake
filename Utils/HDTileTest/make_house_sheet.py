"""Collect every sprite of one house and lay them out on a single context sheet.

The sheet is meant to be handed to an image model together with the manifest text, so that it
knows what it is looking at before upscaling the sprites one by one. The individual sprites are
exported next to it (with alpha, colour bled) - those are what actually gets upscaled.

Sprite ids come from data/defines/houses.dat, which the game reads into TKMHouseSpecLegacy
(see src/res/KM_ResHouses.pas). Snow sprites are not in the dat, they are hardcoded in
HOUSE_DAT_X in that same unit, so they are parsed out of the source.

Run from the repository root:
    python Utils\\HDTileTest\\make_house_sheet.py --house sawmill
"""

import argparse
import json
import os
import re
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_hd_test_tiles import read_rxx, write_png, bleed_colors


# --- houses.dat layout (packed records, see TKMHouseSpecLegacy) ---------------------------------

ANIM_SIZE = 30 * 2 + 2 + 4 + 4          # Step[1..30]: SmallInt; Count: SmallInt; MoveX, MoveY: Integer
HOUSE_ACTIONS = ['Work1', 'Work2', 'Work3', 'Work4', 'Work5',
                 'Smoke', 'Flagpole', 'Idle',
                 'Flag1', 'Flag2', 'Flag3',
                 'Fire1', 'Fire2', 'Fire3', 'Fire4', 'Fire5', 'Fire6', 'Fire7', 'Fire8']
RECORD_SIZE = 1688                      # verified against the file size
BEAST_ANIM_SIZE = 2 * 5 * 3 * ANIM_SIZE  # fBeastAnim, read before the house records

# Order of the records in the dat file (HOUSE_ID_TO_TYPE in KM_ResHouses.pas). 'none' is a gap
DAT_ORDER = ['sawmill', 'ironsmithy', 'weaponsmithy', 'coalmine', 'ironmine',
             'goldmine', 'fishermans', 'bakery', 'farm', 'woodcutters',
             'armorsmithy', 'store', 'stables', 'school', 'quarry',
             'metallurgists', 'swine', 'watchtower', 'townhall', 'weaponworkshop',
             'armorworkshop', 'barracks', 'mill', 'siegeworkshop', 'butchers',
             'tannery', 'none', 'inn', 'vineyard']


def read_houses_dat(path):
    """{house name: {'stone':.., 'wood':.., 'supply_in':[[..]], 'supply_out':[[..]], 'anims':{name:[steps]}}}
    Sprite ids are returned 1-based, the way the engine uses them (dat value + 1)."""
    raw = open(path, 'rb').read()
    expected = BEAST_ANIM_SIZE + 29 * RECORD_SIZE
    if len(raw) != expected:
        raise SystemExit('houses.dat is %d bytes, expected %d - the record layout changed?'
                         % (len(raw), expected))

    def anim(base):
        steps = struct.unpack_from('<30h', raw, base)
        count = struct.unpack_from('<h', raw, base + 60)[0]
        return [s + 1 for s in steps[:max(count, 0)]]

    houses = {}
    for i, name in enumerate(DAT_ORDER):
        if name == 'none':
            continue
        o = BEAST_ANIM_SIZE + i * RECORD_SIZE
        stone, wood = struct.unpack_from('<2h', raw, o)
        sup_in = [list(struct.unpack_from('<5h', raw, o + 8 + 10 * k)) for k in range(4)]
        sup_out = [list(struct.unpack_from('<5h', raw, o + 48 + 10 * k)) for k in range(4)]
        anims = {}
        for k, act in enumerate(HOUSE_ACTIONS):
            anims[act] = anim(o + 88 + k * ANIM_SIZE)
        houses[name] = {
            'stone': stone + 1,
            'wood': wood + 1,
            # A dat value of -1 means 'no sprite'; +1 turns it into 0, which the engine skips
            'supply_in': [[v + 1 for v in row] for row in sup_in],
            'supply_out': [[v + 1 for v in row] for row in sup_out],
            'anims': anims,
        }
    return houses


def read_snow_pics(pas_path):
    """SnowSpriteId per house out of the hardcoded HOUSE_DAT_X table. Keyed by the comment name."""
    src = open(pas_path, 'r', encoding='utf-8', errors='replace').read()
    start = src.index('HOUSE_DAT_X: array')
    end = src.find('\n  );', start)            # the table ends with the closing paren of the array
    block = src[start:end if end > 0 else len(src)]
    names = re.findall(r'\(\s*//\s*(.+)', block)
    snow = re.findall(r'SnowSpriteId:\s*(-?\d+)', block)
    # The comments spell the houses slightly differently from the dat order ('Fisher hut' vs
    # 'fishermans', 'Wineyard' vs 'vineyard'), so map the odd ones explicitly
    ALIAS = {'fisherhut': 'fishermans', 'metallurgist': 'metallurgists',
             'wineyard': 'vineyard', 'woodcutter': 'woodcutters', 'marketplace': 'market'}
    result = {}
    for n, s in zip(names, snow):
        key = re.sub(r'[^a-z]', '', n.lower())
        result[ALIAS.get(key, key)] = int(s) + 1   # engine uses SnowPic + 1
    return result


# --- sprite collecting -------------------------------------------------------------------------

def collect(house, dat, snow_pics, with_fire=False):
    """[(sprite id, role)] in a sensible reading order, deduplicated."""
    h = dat[house]
    out = []
    seen = set()

    def add(sid, role):
        if sid <= 0 or sid in seen:
            return
        seen.add(sid)
        out.append((sid, role))

    add(h['wood'], 'construction: wood frame')
    add(h['stone'], 'construction: stone / finished')
    if house in snow_pics:
        add(snow_pics[house], 'construction: snow covered')

    for k, act in enumerate(HOUSE_ACTIONS):
        if act.startswith('Fire') and not with_fire:
            continue
        for step, sid in enumerate(h['anims'][act], 1):
            add(sid, 'animation %s step %d' % (act, step))

    for w, row in enumerate(h['supply_in'], 1):
        for cnt, sid in enumerate(row, 1):
            add(sid, 'ware in, slot %d, count %d' % (w, cnt))

    for w, row in enumerate(h['supply_out'], 1):
        for cnt, sid in enumerate(row, 1):
            add(sid, 'ware out, slot %d, count %d' % (w, cnt))

    return out


# --- drawing -----------------------------------------------------------------------------------

# 4x6 digits, enough to number the cells. Anything wordy belongs in the manifest text
DIGITS = [
    '0110 1001 1001 1001 1001 0110', '0010 0110 0010 0010 0010 0111',
    '0110 1001 0001 0010 0100 1111', '1110 0001 0110 0001 1001 0110',
    '0010 0110 1010 1111 0010 0010', '1111 1000 1110 0001 1001 0110',
    '0110 1000 1110 1001 1001 0110', '1111 0001 0010 0100 0100 0100',
    '0110 1001 0110 1001 1001 0110', '0110 1001 1001 0111 0001 0110',
]


def draw_digit(buf, bw, x, y, digit, scale, colour):
    rows = DIGITS[digit].split()
    for ry, row in enumerate(rows):
        for rx, bit in enumerate(row):
            if bit != '1':
                continue
            for sy in range(scale):
                for sx in range(scale):
                    px, py = x + rx * scale + sx, y + ry * scale + sy
                    if 0 <= px < bw:
                        o = (py * bw + px) * 4
                        if 0 <= o < len(buf) - 3:
                            buf[o:o + 4] = colour


def draw_number(buf, bw, x, y, num, scale, colour):
    for i, ch in enumerate(str(num)):
        draw_digit(buf, bw, x + i * 5 * scale, y, int(ch), scale, colour)


def blit(dst, dw, dh, src, sw, sh, x, y, on_background):
    """Alpha-composite src onto dst at x,y. on_background: the sheet is opaque, cells keep alpha."""
    for sy in range(sh):
        dy = y + sy
        if dy < 0 or dy >= dh:
            continue
        for sx in range(sw):
            dx = x + sx
            if dx < 0 or dx >= dw:
                continue
            so = (sy * sw + sx) * 4
            a = src[so + 3]
            if a == 0:
                continue
            do = (dy * dw + dx) * 4
            if a == 255 or not on_background:
                dst[do:do + 4] = src[so:so + 4]
            else:
                for c in range(3):
                    dst[do + c] = (src[so + c] * a + dst[do + c] * (255 - a)) // 255
                dst[do + 3] = 255


def build_sheet(cells, cols, bg, label_h, pad):
    """cells: [(w, h, rgba, index)] -> (sheet w, h, buffer, [placement dicts])"""
    cw = max(c[0] for c in cells) + 2 * pad
    ch = max(c[1] for c in cells) + 2 * pad + label_h
    rows = (len(cells) + cols - 1) // cols
    W, H = cw * cols, ch * rows
    buf = bytearray()
    for _ in range(W * H):
        buf += bytes(bg)

    places = []
    for i, (w, h, rgba, idx) in enumerate(cells):
        cx, cy = (i % cols) * cw, (i // cols) * ch
        # Cell border, so the model sees where one sprite ends and the next begins
        for x in range(cx, cx + cw):
            for y in (cy, cy + ch - 1):
                o = (y * W + x) * 4
                buf[o:o + 4] = bytes((90, 90, 96, 255))
        for y in range(cy, cy + ch):
            for x in (cx, cx + cw - 1):
                o = (y * W + x) * 4
                buf[o:o + 4] = bytes((90, 90, 96, 255))

        draw_number(buf, W, cx + pad, cy + 3, idx, 2, bytes((230, 230, 60, 255)))

        ox = cx + (cw - w) // 2
        oy = cy + label_h + (ch - label_h - h) // 2
        blit(buf, W, H, rgba, w, h, ox, oy, True)
        places.append({'index': idx, 'x': ox, 'y': oy, 'w': w, 'h': h})

    return W, H, buf, places


# --- main --------------------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--house', required=True, help='house name, e.g. sawmill (see houses.dat order)')
    ap.add_argument('--rxx', default=r'data\Sprites\Houses_a.rxx')
    ap.add_argument('--dat', default=r'data\defines\houses.dat')
    ap.add_argument('--pas', default=r'src\res\KM_ResHouses.pas')
    ap.add_argument('--out', default=r'Utils\HDTileTest\house_sheets')
    ap.add_argument('--cols', type=int, default=6)
    ap.add_argument('--bleed', type=int, default=3, help='colour bleed into transparent pixels (0 = off)')
    ap.add_argument('--with-fire', action='store_true', help='include the generic burning animation')
    ap.add_argument('--list', action='store_true', help='just list the houses and exit')
    args = ap.parse_args()

    dat = read_houses_dat(args.dat)
    if args.list:
        for name in sorted(dat):
            print(name)
        return

    house = re.sub(r'[^a-z]', '', args.house.lower())
    if house not in dat:
        raise SystemExit('unknown house %r, try --list' % args.house)

    snow_pics = read_snow_pics(args.pas)
    wanted = collect(house, dat, snow_pics, args.with_fire)

    sprites = read_rxx(args.rxx, with_masks=True)
    missing = [sid for sid, _ in wanted if sid not in sprites]
    if missing:
        print('WARNING: %d sprite ids are not in the RXX: %s' % (len(missing), missing[:10]))
    wanted = [(sid, role) for sid, role in wanted if sid in sprites]

    out_dir = os.path.join(args.out, house)
    os.makedirs(out_dir, exist_ok=True)

    cells, mask_cells, manifest = [], [], []
    for idx, (sid, role) in enumerate(wanted, 1):
        w, h, rgba, mask = sprites[sid]
        data = bytearray(rgba)
        if args.bleed:
            data = bleed_colors(w, h, data, args.bleed)

        name = '%02d_%04d.png' % (idx, sid)
        write_png(os.path.join(out_dir, name), w, h, data)
        cells.append((w, h, data, idx))

        if mask:
            mdata = bytearray(w * h * 4)
            for i in range(w * h):
                mdata[4 * i:4 * i + 4] = bytes((mask[i], mask[i], mask[i], 255))
            write_png(os.path.join(out_dir, '%02d_%04dm.png' % (idx, sid)), w, h, mdata)
            mask_cells.append((w, h, mdata, idx))

        manifest.append({'index': idx, 'sprite_id': sid, 'role': role,
                         'width': w, 'height': h, 'has_mask': bool(mask), 'file': name})

    W, H, buf, places = build_sheet(cells, args.cols, (28, 28, 32, 255), 14, 6)
    sheet = os.path.join(args.out, '%s_sheet.png' % house)
    write_png(sheet, W, H, buf)
    for p in places:
        manifest[p['index'] - 1].update({'sheet_x': p['x'], 'sheet_y': p['y']})

    if mask_cells:
        mW, mH, mbuf, _ = build_sheet(mask_cells, args.cols, (28, 28, 32, 255), 14, 6)
        write_png(os.path.join(args.out, '%s_masks.png' % house), mW, mH, mbuf)

    # The text the model should get next to the image: it reads this far more reliably than rendered labels
    lines = ['House: %s' % house,
             'Sheet: %s (%dx%d), cells numbered top-left in yellow' % (os.path.basename(sheet), W, H),
             'Sprites are KaM Remake house sprites, 1x resolution, transparent background.',
             'Masks (separate image) are NOT art: on whole-building sprites they encode the build order',
             'for the construction animation, on small sprites they are the team colour mask.',
             '']
    for m in manifest:
        lines.append('%2d) sprite %4d  %3dx%-3d  %-34s %s'
                     % (m['index'], m['sprite_id'], m['width'], m['height'], m['role'],
                        'has mask' if m['has_mask'] else ''))
    txt = os.path.join(args.out, '%s_manifest.txt' % house)
    open(txt, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    json.dump(manifest, open(os.path.join(args.out, '%s_manifest.json' % house), 'w'), indent=1)

    print('%s: %d sprites (%d with mask)' % (house, len(manifest), len(mask_cells)))
    print('sheet    : %s (%dx%d)' % (sheet, W, H))
    print('sprites  : %s' % out_dir)
    print('manifest : %s' % txt)


if __name__ == '__main__':
    main()
