"""
Generate upscaled test sprites for the HD rendering work.

Reads an RXX (Tileset, Trees, Houses, Units, ...), upscales every sprite by SCALE (bilinear) and writes
X_NNNN.png files into an overload folder under "Modding graphics", where the game picks them up at
startup (LoadSprites -> OverloadRXDataFromFolder). The engine derives Scale = SCALE from the size ratio.

Also written:
  X_NNNNm.png  - team colour mask ("plain" mask, used as is by the engine) when the sprite has one (houses, units)
Not written:
  X_NNNN.txt   - pivots: the engine rescales the original pivot automatically when it derives the HD scale

Transparent pixels in the RXX carry the KaM transparency colour (lilac). With linear filtering that colour
bleeds into the sprite edges, so before upscaling the RGB of transparent pixels is replaced by the nearest
opaque colour (--bleed passes of dilation); alpha stays 0.

Pure Python: no Pillow needed (RXX = zlib stream, PNG written by hand).

Usage (from the repository root):
  python make_hd_test_tiles.py                                   # tiles, 4x, masks 4949-4992 skipped
  python make_hd_test_tiles.py --rxx data\\Sprites\\Trees_a.rxx  --rx 1 --out "Modding graphics/hd_trees_test"
  python make_hd_test_tiles.py --rxx data\\Sprites\\Houses_a.rxx --rx 2 --out "Modding graphics/hd_houses_test" --filter xbr

External upscaler (e.g. Real-ESRGAN) round trip:
  python make_hd_test_tiles.py --rxx data\\Sprites\\Houses_a.rxx --rx 2 --export-sd esrgan_in
  realesrgan-ncnn-vulkan.exe -i esrgan_in -o esrgan_out -n realesrgan-x4plus -s 4 -f png
  python make_hd_test_tiles.py --rxx data\\Sprites\\Houses_a.rxx --rx 2 --import-hd esrgan_out --out "Modding graphics/hd_houses_esrgan"
"""
import argparse
import json
import math
import os
import struct
import sys
import zlib

# 0-based ids of the transition masks (TILE_MASKS_FOR_LAYERS in KM_ResTilesetTypes.pas)
MASK_IDS = set(range(4949, 4953)) | set(range(4959, 4963)) | set(range(4969, 4973)) \
         | set(range(4979, 4983)) | set(range(4989, 4993))
MASK_IDS_ARG = ",".join(str(i) for i in sorted(MASK_IDS))

# TKMTerrainKind (in enum order) and BASE_TERRAIN, the plain 0-based tile of each kind (KM_ResTilesetTypes.pas)
TERRAIN_KINDS = ("tkCustom", "tkGrass", "tkMoss", "tkPaleGrass", "tkCoastSand", "tkGrassSand1", "tkGrassSand2",
                 "tkGrassSand3", "tkSand", "tkGrassDirt", "tkDirt", "tkCobbleStone", "tkGrassyWater", "tkSwamp", "tkIce",
                 "tkSnowOnGrass", "tkSnowOnDirt", "tkSnow", "tkDeepSnow", "tkStone", "tkGoldMount", "tkIronMount",
                 "tkAbyss", "tkGravel", "tkCoal", "tkGold", "tkIron", "tkWater", "tkFastWater", "tkLava")
BASE_TERRAIN = (0, 0, 8, 17, 32, 26, 27, 28, 29, 34, 35, 215, 48, 40, 44, 315, 47, 46, 45, 132, 159, 164, 245, 20, 155,
                147, 151, 192, 209, 7)
BASE_TILE = dict(zip(TERRAIN_KINDS, BASE_TERRAIN))
TILE_CONTEXT_PAD = 2  # SD px of neighbour context around a transition tile; bilinear reads 1


def load_tile_corners(path):
    """{0-based tile id: [terrain kind of the TL, TR, BR, BL corner]} from data/defines/tiles.json."""
    with open(path, encoding="utf-8-sig") as f:
        return {t["ID"]: t["CornersTerKinds"] for t in json.load(f)["Tiles"] if t.get("CornersTerKinds")}


def upscale_tile(tile0, w, h, rgba, scale, corners, sprites):
    """Upscale one terrain tile so that its border is as soft as its inside.

    Upscaling every tile on its own with a clamped border leaves a hard one-pixel step on every tile border,
    while the inside gets soft - the tile grid shows. What the tile needs next to it depends on the tile:
      pure terrain (all 4 corners one kind): wrap around, the tile continues into itself
      transition (2+ kinds): pad each side with the plain tile of the terrain at the nearest corner
      anything else (no terrain kind, tkCustom corner, a mask): clamped, as before
    Returns (W, H, bytes, how) with how in 'wrap' / 'context' / 'clamp'."""
    kinds = corners.get(tile0)
    if not kinds or "tkCustom" in kinds or tile0 in MASK_IDS:
        return upscale_bilinear(w, h, rgba, scale) + ("clamp",)
    if len(set(kinds)) == 1:
        return upscale_bilinear(w, h, rgba, scale, wrap=True) + ("wrap",)

    # The plain tile of each corner's terrain, same size as this one, or we cannot use it as context
    bases = []
    for kind in kinds:
        base = sprites.get(BASE_TILE[kind] + 1)
        if base is None or (base[0], base[1]) != (w, h):
            return upscale_bilinear(w, h, rgba, scale) + ("clamp",)
        bases.append(base[2])

    pad = TILE_CONTEXT_PAD
    pw, ph = w + 2 * pad, h + 2 * pad
    src = bytearray(pw * ph * 4)
    for y in range(ph):
        ty = y - pad
        for x in range(pw):
            tx = x - pad
            if 0 <= tx < w and 0 <= ty < h:
                px = rgba
            else:
                # 0 = TL, 1 = TR, 2 = BR, 3 = BL (TKMTerrain.GetVerticeTerKinds)
                right, bottom = tx >= w // 2, ty >= h // 2
                px = bases[(2 if right else 3) if bottom else (1 if right else 0)]
            i = ((ty % h) * w + tx % w) * 4
            src[(y * pw + x) * 4:(y * pw + x) * 4 + 4] = px[i:i + 4]

    big_w, _, big = upscale_bilinear(pw, ph, bytes(src), scale)
    W, H, off = w * scale, h * scale, pad * scale
    out = bytearray(W * H * 4)
    for y in range(H):
        start = ((y + off) * big_w + off) * 4
        out[y * W * 4:(y + 1) * W * 4] = big[start:start + W * 4]
    return W, H, bytes(out), "context"


def read_rxx(path, with_masks=False, units=False):
    """Returns {1-based id: (w, h, rgba)} or, with_masks, {id: (w, h, rgba, mask_or_None)}.
    units: Units.rxx carries an extra SizeNoShadow rect (4 x SmallInt) per sprite."""
    with open(path, "rb") as f:
        raw = f.read()
    head = raw[:4]
    if head == b"RXX1":
        body = raw[4 + 32:]
    elif head == b"RXX2":
        (meta_len,) = struct.unpack_from("<H", raw, 4)
        body = raw[6 + meta_len:]
    elif raw[:2] == b"\x78\xda":
        body = raw
    else:
        raise SystemExit("Unknown RXX header: %r" % head)

    data = zlib.decompress(body)
    pos = 0
    (count,) = struct.unpack_from("<i", data, pos)
    pos += 4
    flags = data[pos:pos + count]
    pos += count

    sprites = {}
    for i in range(count):
        if flags[i] != 1:
            continue
        w, h = struct.unpack_from("<HH", data, pos)  # Size: X,Y Word
        pos += 4
        pos += 4  # Pivot: X,Y SmallInt
        if units:
            pos += 8  # SizeNoShadow: Left, Top, Right, Bottom SmallInt
        n = w * h
        rgba = data[pos:pos + 4 * n]
        pos += 4 * n
        has_mask = data[pos]
        pos += 1
        mask = None
        if has_mask:
            mask = data[pos:pos + n]
            pos += n
        sprites[i + 1] = (w, h, rgba, mask) if with_masks else (w, h, rgba)  # 1-based ids, like fRXData
    return sprites


def read_rxa(path, units=False):
    """Read a shipped .rxa (atlas pack): {1-based id: (w, h, rgba, mask_or_None, (pivot_x, pivot_y), sns_or_None)}.
    The RXA holds per-sprite info + packed atlases, so the sprites are cut out of the atlases here.
    This is the only place the interpolated ('smooth animation') frames exist, they are not in the RXX files."""
    with open(path, "rb") as f:
        raw = f.read()
    head = raw[:4]
    if head in (b"RXX2", b"RXX3"):
        (meta_len,) = struct.unpack_from("<H", raw, 4)
        body = raw[6 + meta_len:]
    elif head == b"RXX1":
        body = raw[4 + 32:]
    else:
        raise SystemExit("Unknown RXA header: %r" % head)
    rxx3 = head == b"RXX3"

    data = zlib.decompress(body)
    pos = 0
    (count,) = struct.unpack_from("<i", data, pos)
    pos += 4
    flags = data[pos:pos + count]
    pos += count

    info = {}
    for i in range(count):
        if flags[i] != 1:
            continue
        w, h, px, py = struct.unpack_from("<HHhh", data, pos)
        pos += 8
        sns = None
        if units:
            sns = struct.unpack_from("<hhhh", data, pos)
            pos += 8
        if rxx3:
            pos += 4  # Scale
        has_mask = data[pos]
        pos += 1
        info[i + 1] = (w, h, px, py, sns, has_mask)

    sprites = {}
    for sat in range(2):  # 0 = base (RGBA), 1 = team colour mask (value in the alpha byte)
        (atlas_count,) = struct.unpack_from("<i", data, pos)
        pos += 4
        for _ in range(atlas_count):
            aw, ah, sprite_count = struct.unpack_from("<HHi", data, pos)
            pos += 8
            entries = [struct.unpack_from("<iHH", data, pos + k * 8) for k in range(sprite_count)]
            pos += sprite_count * 8
            pos += 1  # TexType (1-byte enum)
            if rxx3:
                pos += 1  # HD flag
            (data_count,) = struct.unpack_from("<i", data, pos)
            pos += 4
            if data_count != aw * ah:
                raise SystemExit("%s: atlas layout mismatch (%d px vs %dx%d), unsupported RXA variant" % (path, data_count, aw, ah))
            atlas = data[pos:pos + 4 * data_count]
            pos += 4 * data_count
            stride = aw * 4
            for sid, ox, oy in entries:
                w, h = info[sid][0], info[sid][1]
                rows = [atlas[(oy + y) * stride + ox * 4:(oy + y) * stride + (ox + w) * 4] for y in range(h)]
                cut = b"".join(rows)
                if sat == 0:
                    sprites[sid] = [w, h, cut, None]
                else:
                    sprites[sid][3] = bytes(cut[3::4])  # mask value is the alpha byte of $FFFFFF|mask<<24

    out = {}
    for sid, (w, h, cut, mask) in sprites.items():
        _, _, px, py, sns, _ = info[sid]
        out[sid] = (w, h, cut, mask, (px, py), sns)
    return out


def bleed_colors(w, h, rgba, passes):
    """Replace the RGB of fully transparent pixels with the average of their coloured 8-neighbours.
    Repeated `passes` times so the colour spreads outwards; alpha is untouched."""
    px = bytearray(rgba)
    colored = bytearray(px[3::4])  # 1 where the pixel carries a meaningful colour (opaque, or bled in an earlier pass)
    for i in range(w * h):
        colored[i] = 1 if colored[i] else 0
    for _ in range(passes):
        todo = [i for i in range(w * h) if not colored[i]]
        if not todo:
            break
        newly = []
        for i in todo:
            y, x = divmod(i, w)
            r = g = b = n = 0
            for dy in (-1, 0, 1):
                yy = y + dy
                if yy < 0 or yy >= h:
                    continue
                for dx in (-1, 0, 1):
                    xx = x + dx
                    if xx < 0 or xx >= w or (dx == 0 and dy == 0):
                        continue
                    j = yy * w + xx
                    if colored[j]:
                        o = j * 4
                        r += px[o]
                        g += px[o + 1]
                        b += px[o + 2]
                        n += 1
            if n:
                o = i * 4
                newly.append((i, (r + n // 2) // n, (g + n // 2) // n, (b + n // 2) // n))
        for i, r, g, b in newly:
            o = i * 4
            px[o] = r
            px[o + 1] = g
            px[o + 2] = b
            colored[i] = 1
    return bytes(px)


def _axis_table(n, scale, wrap=False):
    """Per output coordinate: (source index 0, source index 1, weight of index 1 in 0..256).
    wrap: past the border the image continues with its opposite edge instead of repeating its own edge pixel."""
    tab = []
    for o in range(n * scale):
        s = (o + 0.5) / scale - 0.5
        if wrap:
            i0 = math.floor(s)
            tab.append((i0 % n, (i0 + 1) % n, int(round((s - i0) * 256))))
            continue
        if s < 0:
            s = 0.0
        i0 = min(int(s), n - 1)
        i1 = min(i0 + 1, n - 1)
        tab.append((i0, i1, int(round((s - i0) * 256))))
    return tab


def upscale_bilinear(w, h, data, scale, channels=4, wrap=False):
    """Separable bilinear upscale of an interleaved `channels`-byte image. Returns (W, H, bytes)."""
    W, H = w * scale, h * scale
    xt = _axis_table(w, scale, wrap)
    yt = _axis_table(h, scale, wrap)
    src = memoryview(data)

    # Horizontal pass: w -> W on every source row
    tmp = bytearray(W * h * channels)
    xt_c = [(i0 * channels + c, i1 * channels + c, wt) for (i0, i1, wt) in xt for c in range(channels)]
    for y in range(h):
        row = src[y * w * channels:(y + 1) * w * channels]
        base = y * W * channels
        for k, (a, b, wt) in enumerate(xt_c):
            tmp[base + k] = (row[a] * (256 - wt) + row[b] * wt + 128) >> 8

    # Vertical pass: h -> H on every output column
    out = bytearray(W * H * channels)
    stride = W * channels
    for Y, (y0, y1, wt) in enumerate(yt):
        r0 = tmp[y0 * stride:(y0 + 1) * stride]
        r1 = tmp[y1 * stride:(y1 + 1) * stride]
        base = Y * stride
        if wt == 0:
            out[base:base + stride] = r0
        else:
            iw = 256 - wt
            out[base:base + stride] = bytes((a * iw + b * wt + 128) >> 8 for a, b in zip(r0, r1))
    return W, H, bytes(out)


def _yuva(px, o):
    r, g, b, a = px[o], px[o + 1], px[o + 2], px[o + 3]
    return (0.299 * r + 0.587 * g + 0.114 * b,
            -0.169 * r - 0.331 * g + 0.5 * b,
            0.5 * r - 0.419 * g - 0.081 * b,
            a)


def xbr2x(w, h, rgba):
    """xBR (Hyllian) 2x pixel-art scaler, level-2 rules as in FFmpeg's vf_xbr, on RGBA.
    Edges are detected in a 5x5 neighbourhood and the 2x2 output block is blended along them,
    so diagonals and curves come out smooth instead of stair-stepped. Alpha takes part in the
    colour distance (transparent vs opaque is a strong edge)."""
    W, H = w * 2, h * 2
    src = memoryview(rgba)
    yuva = [_yuva(src, i * 4) for i in range(w * h)]

    def df(p, q):
        a, b = yuva[p], yuva[q]
        return abs(a[0] - b[0]) * 48 + abs(a[1] - b[1]) * 7 + abs(a[2] - b[2]) * 6 + abs(a[3] - b[3]) * 48

    def eq(p, q):
        return df(p, q) < 155

    def idx(x, y):
        return min(max(y, 0), h - 1) * w + min(max(x, 0), w - 1)

    def blend(dst, p, m):  # dst: [r,g,b,a] list, p: source index, weight m/8 for p
        o = p * 4
        for c in range(4):
            dst[c] = (dst[c] * (8 - m) + src[o + c] * m + 4) >> 3

    def rot(dx, dy, r):
        for _ in range(r):
            dx, dy = -dy, dx
        return dx, dy

    out = bytearray(W * H * 4)
    for y in range(h):
        for x in range(w):
            e = idx(x, y)
            n = [[src[e * 4 + c] for c in range(4)] for _ in range(4)]  # N0 tl, N1 tr, N2 bl, N3 br

            for r in range(4):
                def P(dx, dy):
                    rx, ry = rot(dx, dy, r)
                    return idx(x + rx, y + ry)

                def N(sx, sy):  # output sub-pixel in the rotated frame -> index into n
                    cx, cy = rot(2 * sx - 1, 2 * sy - 1, r)
                    return ((cy + 1) // 2) * 2 + (cx + 1) // 2

                PE = e
                PA, PB, PC = P(-1, -1), P(0, -1), P(1, -1)
                PD, PF = P(-1, 0), P(1, 0)
                PG, PH, PI = P(-1, 1), P(0, 1), P(1, 1)
                B1, C1 = P(0, -2), P(1, -2)
                A0, D0, G0 = P(-2, -1), P(-2, 0), P(-2, 1)
                C4, F4, I4 = P(2, -1), P(2, 0), P(2, 1)
                G5, H5, I5 = P(-1, 2), P(0, 2), P(1, 2)

                if not (not eq(PE, PH) and not eq(PE, PF)):
                    continue
                ev = df(PE, PC) + df(PE, PG) + df(PI, H5) + df(PI, F4) + (df(PH, PF) * 4)
                iv = df(PH, PD) + df(PH, I5) + df(PF, I4) + df(PF, PB) + (df(PE, PI) * 4)
                if not (ev < iv and (
                        (not eq(PF, PB) and not eq(PH, PD))
                        or (eq(PE, PI) and (not eq(PF, I4) and not eq(PH, I5)))
                        or eq(PE, PG) or eq(PE, PC))):
                    continue
                ke = df(PF, PG)
                ki = df(PH, PC)
                ex2 = (not eq(PE, PC)) and (not eq(PB, PC))
                ex3 = (not eq(PE, PG)) and (not eq(PD, PG))
                px = PF if df(PE, PF) <= df(PE, PH) else PH
                n3, n2, n1 = n[N(1, 1)], n[N(0, 1)], n[N(1, 0)]
                left = (ke * 2 <= ki) and ex3
                up = (ke >= ki * 2) and ex2
                if left and up:
                    blend(n3, px, 6)
                    blend(n2, px, 2)
                    blend(n1, px, 2)
                elif left:
                    blend(n3, px, 6)
                    blend(n2, px, 2)
                elif up:
                    blend(n3, px, 6)
                    blend(n1, px, 2)
                else:
                    blend(n3, px, 4)

            for k, (sx, sy) in enumerate(((0, 0), (1, 0), (0, 1), (1, 1))):
                o = ((2 * y + sy) * W + 2 * x + sx) * 4
                out[o:o + 4] = bytes(n[k])
    return W, H, bytes(out)


def upscale_xbr(w, h, rgba, scale):
    """xBR applied log2(scale) times (2x -> 4x -> 8x). scale must be a power of two."""
    s = 1
    while s < scale:
        w, h, rgba = xbr2x(w, h, rgba)
        s *= 2
    if s != scale:
        raise SystemExit("--filter xbr needs a power-of-two scale, got %d" % scale)
    return w, h, rgba


def box_blur(w, h, rgba, radius, passes=2):
    """Separable box blur on all 4 channels (edge clamped). Two passes ~ gaussian."""
    src = bytearray(rgba)
    for _ in range(passes):
        # horizontal
        tmp = bytearray(len(src))
        for y in range(h):
            row = y * w * 4
            for c in range(4):
                acc = 0
                # initial window [-radius, radius] with clamping
                for k in range(-radius, radius + 1):
                    acc += src[row + min(max(k, 0), w - 1) * 4 + c]
                n = 2 * radius + 1
                for x in range(w):
                    tmp[row + x * 4 + c] = (acc + n // 2) // n
                    out_i = min(max(x - radius, 0), w - 1)
                    in_i = min(max(x + radius + 1, 0), w - 1)
                    acc += src[row + in_i * 4 + c] - src[row + out_i * 4 + c]
        # vertical
        src = bytearray(len(tmp))
        for x in range(w):
            for c in range(4):
                col = x * 4 + c
                acc = 0
                for k in range(-radius, radius + 1):
                    acc += tmp[min(max(k, 0), h - 1) * w * 4 + col]
                n = 2 * radius + 1
                for y in range(h):
                    src[y * w * 4 + col] = (acc + n // 2) // n
                    out_i = min(max(y - radius, 0), h - 1)
                    in_i = min(max(y + radius + 1, 0), h - 1)
                    acc += tmp[in_i * w * 4 + col] - tmp[out_i * w * 4 + col]
    return bytes(src)


def write_png(path, w, h, rgba):
    def chunk(tag, payload):
        c = struct.pack(">I", len(payload)) + tag + payload
        return c + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF)

    stride = w * 4
    raw = b"".join(b"\x00" + rgba[y * stride:(y + 1) * stride] for y in range(h))
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 6))
    png += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


def read_png(path):
    """Minimal PNG reader: 8-bit RGB / RGBA / grey / grey+alpha, non-interlaced. Returns (w, h, rgba bytes)."""
    with open(path, "rb") as f:
        data = f.read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit("%s: not a PNG" % path)
    pos = 8
    idat = []
    w = h = None
    while pos < len(data):
        (ln,) = struct.unpack_from(">I", data, pos)
        tag = data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + ln]
        pos += 12 + ln
        if tag == b"IHDR":
            w, h, depth, ctype, _, _, interlace = struct.unpack(">IIBBBBB", body)
            if depth != 8 or interlace != 0 or ctype not in (0, 2, 4, 6):
                raise SystemExit("%s: unsupported PNG (need 8-bit non-interlaced RGB/RGBA/grey), got depth %d type %d"
                                 % (path, depth, ctype))
        elif tag == b"IDAT":
            idat.append(body)
        elif tag == b"IEND":
            break
    ch = {0: 1, 2: 3, 4: 2, 6: 4}[ctype]
    raw = zlib.decompress(b"".join(idat))
    stride = w * ch
    out = bytearray(w * h * ch)
    prev = bytearray(stride)
    p = 0
    for y in range(h):
        ft = raw[p]
        p += 1
        line = bytearray(raw[p:p + stride])
        p += stride
        if ft == 1:
            for i in range(ch, stride):
                line[i] = (line[i] + line[i - ch]) & 0xFF
        elif ft == 2:
            for i in range(stride):
                line[i] = (line[i] + prev[i]) & 0xFF
        elif ft == 3:
            for i in range(stride):
                a = line[i - ch] if i >= ch else 0
                line[i] = (line[i] + ((a + prev[i]) >> 1)) & 0xFF
        elif ft == 4:
            for i in range(stride):
                a = line[i - ch] if i >= ch else 0
                b = prev[i]
                c = prev[i - ch] if i >= ch else 0
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 0xFF
        out[y * stride:(y + 1) * stride] = line
        prev = line
    if ch == 4:
        return w, h, bytes(out)
    rgba = bytearray(w * h * 4)
    if ch == 3:
        rgba[0::4] = out[0::3]
        rgba[1::4] = out[1::3]
        rgba[2::4] = out[2::3]
        rgba[3::4] = b"\xff" * (w * h)
    elif ch == 2:
        rgba[0::4] = rgba[1::4] = rgba[2::4] = out[0::2]
        rgba[3::4] = out[1::2]
    else:
        rgba[0::4] = rgba[1::4] = rgba[2::4] = out
        rgba[3::4] = b"\xff" * (w * h)
    return w, h, bytes(rgba)


def mask_to_rgba(mask):
    """Grey RGBA (R=G=B=mask, A=255). The engine reads the red channel of an m.png as the mask value."""
    out = bytearray(len(mask) * 4)
    out[0::4] = mask
    out[1::4] = mask
    out[2::4] = mask
    out[3::4] = b"\xff" * len(mask)
    return bytes(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rxx", default=os.path.join("data", "Sprites", "Tileset.rxx"))
    ap.add_argument("--rxa", default="",
                    help="read the sprites from this shipped .rxa instead of --rxx (the only source of the interpolated "
                         "animation frames). Output files get an '@Nx' suffix and a pivot .txt, because these sprites "
                         "have no original in the RXX the engine could derive the scale from")
    ap.add_argument("--interp-only", action="store_true",
                    help="with --rxa: only the sprites that are NOT in --rxx (i.e. the interpolated frames)")
    ap.add_argument("--rx", type=int, default=7,
                    help="RX number used in the file name prefix: 1=Trees 2=Houses 3=Units 4=GUI 5=GUIMain 6=Custom 7=Tileset")
    ap.add_argument("--out", default=os.path.join("Modding graphics", "hd_tiles_test"))
    ap.add_argument("--scale", type=int, default=4)
    ap.add_argument("--skip", default="", help="comma separated 0-based tile ids to leave at original resolution")
    ap.add_argument("--max-id", type=int, default=0, help="only tiles with 0-based id <= this (0 = all)")
    ap.add_argument("--only", default="", help="comma separated 0-based tile ids to (re)generate, nothing else")
    ap.add_argument("--mask-blur", type=int, default=0,
                    help="blur radius (HD px) applied to transition masks to widen their edge band (0 = off)")
    ap.add_argument("--bleed", type=int, default=3,
                    help="dilation passes that push opaque colours into transparent pixels before upscaling (0 = off)")
    ap.add_argument("--no-masks", action="store_true", help="do not write X_NNNNm.png team colour masks")
    ap.add_argument("--filter", choices=("bilinear", "xbr"), default="bilinear",
                    help="bilinear = smooth blur-up; xbr = pixel-art edge-aware scaler (crisp edges, power-of-two scale)")
    ap.add_argument("--tiles-json", default=os.path.join("data", "defines", "tiles.json"),
                    help="terrain kind of every tile corner; tiles (--rx 7, bilinear) use it to upscale with their "
                         "neighbours in mind, so the tile grid does not show")
    ap.add_argument("--no-tile-context", action="store_true",
                    help="upscale every tile on its own with a clamped border (the old behaviour, shows the tile grid)")
    ap.add_argument("--export-sd", metavar="DIR", default="",
                    help="write the selected sprites at ORIGINAL size (colour-bled) into DIR for an external upscaler "
                         "(e.g. Real-ESRGAN); nothing is written to --out")
    ap.add_argument("--import-hd", metavar="DIR", default="",
                    help="take the upscaled X_NNNN.png files from DIR (must be exactly --scale times the original), "
                         "generate the masks and write everything to --out")
    args = ap.parse_args()

    skip = set(int(s) for s in args.skip.split(",") if s.strip())
    only = set(int(s) for s in args.only.split(",") if s.strip())
    is_units = args.rx == 3
    extra = {}  # sid -> (pivot, sns) for RXA sources
    if args.rxa:
        rxa = read_rxa(args.rxa, units=is_units)
        base_ids = set(read_rxx(args.rxx, units=is_units)) if args.interp_only else set()
        sprites = {}
        for sid, (w, h, rgba, mask, pivot, sns) in rxa.items():
            if args.interp_only and sid in base_ids:
                continue
            sprites[sid] = (w, h, rgba, mask)
            extra[sid] = (pivot, sns)
        print("RXA: %d sprites%s" % (len(sprites), " (interpolated frames only)" if args.interp_only else ""), file=sys.stderr)
    else:
        sprites = read_rxx(args.rxx, with_masks=True, units=is_units)
    out_dir = args.export_sd if args.export_sd else args.out
    os.makedirs(out_dir, exist_ok=True)

    corners = {}
    if args.rx == 7 and args.filter == "bilinear" and not args.no_tile_context:
        corners = load_tile_corners(args.tiles_json)
    tile_upscale_kinds = {"wrap": 0, "context": 0, "clamp": 0}

    done = 0
    masks = 0
    for sid in sorted(sprites):
        tile0 = sid - 1  # 0-based id, as used in TILE_MASKS_FOR_LAYERS
        if tile0 in skip:
            continue
        if only and tile0 not in only:
            continue
        if args.max_id and tile0 > args.max_id:
            continue
        w, h, rgba, mask = sprites[sid]
        if w * h == 0:
            continue
        name = "%d_%04d.png" % (args.rx, sid)
        # RXA sprites: explicit scale in the name + pivot file, see --rxa help
        out_name = "%d_%04d@%dx.png" % (args.rx, sid, args.scale) if args.rxa else name
        if args.bleed and args.rx != 7:
            rgba = bleed_colors(w, h, rgba, args.bleed)

        if args.export_sd:
            # Original size, colour-bled, for an external upscaler. Masks are generated on import from the RXX
            write_png(os.path.join(out_dir, name), w, h, rgba)
            done += 1
            continue

        if args.import_hd:
            src = os.path.join(args.import_hd, name)
            if not os.path.exists(src):
                print("  missing %s, skipped" % src, file=sys.stderr)
                continue
            W, H, big = read_png(src)
            if (W, H) != (w * args.scale, h * args.scale):
                raise SystemExit("%s is %dx%d, expected %dx%d (%d x %dx%d)"
                                 % (src, W, H, w * args.scale, h * args.scale, args.scale, w, h))
        elif args.filter == "xbr":
            W, H, big = upscale_xbr(w, h, rgba, args.scale)
        elif corners:
            W, H, big, how = upscale_tile(tile0, w, h, rgba, args.scale, corners, sprites)
            tile_upscale_kinds[how] += 1
        else:
            W, H, big = upscale_bilinear(w, h, rgba, args.scale)
        if args.mask_blur and tile0 in MASK_IDS:
            big = box_blur(W, H, big, args.mask_blur)
        write_png(os.path.join(args.out, out_name), W, H, big)
        if mask is not None and not args.no_masks:
            _, _, big_mask = upscale_bilinear(w, h, mask, args.scale, channels=1)
            write_png(os.path.join(args.out, out_name[:-4] + "m.png"), W, H, mask_to_rgba(big_mask))
            masks += 1
        if args.rxa:
            # Pivot (and SizeNoShadow for units) in the PNG's own pixels, as the engine reads a .txt next to the PNG
            (px, py), sns = extra[sid]
            lines = [px * args.scale, py * args.scale]
            if is_units:
                lines += [v * args.scale for v in (sns or (0, 0, 0, 0))]
            with open(os.path.join(args.out, out_name[:-4] + ".txt"), "w") as f:
                f.write("".join("%d\n" % v for v in lines))
        done += 1
        if done % 100 == 0:
            print("  %d sprites..." % done, file=sys.stderr)

    if args.export_sd:
        print("Exported %d sprites at original size to %s (run the external upscaler on them, then use --import-hd)"
              % (done, out_dir))
    else:
        print("Wrote %d sprites (x%d, %d with team colour mask) to %s, skipped %d, source sprites: %d"
              % (done, args.scale, masks, args.out, len(skip & set(s - 1 for s in sprites)), len(sprites)))
        if corners:
            print("Tiles: %(wrap)d pure (wrapped), %(context)d transitions (neighbour context), "
                  "%(clamp)d other (clamped)" % tile_upscale_kinds)


if __name__ == "__main__":
    main()
