"""
Comparison images for the terrain transitions in HD.

Writes into --out:
  1_handdrawn_sd.png / 1_handdrawn_hd.png  hand-drawn transition tiles of the original tileset, SD and HD
  2_masks.png                              the 20 layer masks: Softest, Soft, Soft2, Hard (pixel), Gradient (alpha)
  3_layer.png                              one generated layer tile (grass + coast sand through a Soft2 straight
                                           mask): SD | HD with the mask sampled nearest (the old engine) |
                                           HD with the mask sampled bilinear (the engine now)

Usage (from the repository root):
  python Utils\\HDTileTest\\make_transition_panels.py --hd "Modding graphics\\hd_tiles_test_skip" --out tile_panels
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_hd_test_tiles as m  # noqa: E402

# 0-based tile ids, as in BASE_TERRAIN / TILE_MASKS_FOR_LAYERS (KM_ResTilesetTypes.pas)
GRASS = 0
COAST_SAND = 32
MASK_FIRST_IDS = (4949, 4959, 4969, 4979, 4989)  # Softest, Soft, Soft2, Hard, Gradient
GRADIENT_FIRST_ID = 4989
SOFT2_STRAIGHT = 4969
HANDDRAWN_SAMPLES = 4


def nearest(w, h, rgba, scale):
    W = w * scale
    out = bytearray(W * h * scale * 4)
    for y in range(h * scale):
        for x in range(W):
            s = ((y // scale) * w + x // scale) * 4
            d = (y * W + x) * 4
            out[d:d + 4] = rgba[s:s + 4]
    return W, h * scale, bytes(out)


def blend(w, h, base, layer, alpha):
    out = bytearray(w * h * 4)
    for i in range(w * h):
        a = alpha[i] / 255
        for c in range(3):
            out[i * 4 + c] = int(base[i * 4 + c] * (1 - a) + layer[i * 4 + c] * a + 0.5)
        out[i * 4 + 3] = 255
    return bytes(out)


def grey(alpha):
    return bytes(v for a in alpha for v in (a, a, a, 255))


def sheet(panels, gap=8, bg=(40, 40, 40)):
    """Places (w, h, rgba) panels left to right on a dark background."""
    W = sum(p[0] for p in panels) + gap * (len(panels) + 1)
    H = max(p[1] for p in panels) + gap * 2
    out = bytearray(bytes(bg + (255,)) * (W * H))
    x0 = gap
    for w, h, rgba in panels:
        for y in range(h):
            d = ((gap + y) * W + x0) * 4
            out[d:d + w * 4] = rgba[y * w * 4:(y + 1) * w * 4]
        x0 += w + gap
    return W, H, bytes(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--sd", default=os.path.join("data", "Sprites", "Tileset.rxx"), help="stock tileset RXX")
    ap.add_argument("--hd", required=True, help="folder with the HD tiles as 7_NNNN.png")
    ap.add_argument("--tiles-json", default=os.path.join("data", "defines", "tiles.json"))
    ap.add_argument("--out", required=True, help="output folder")
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)

    sd = m.read_rxx(args.sd)

    def hd_tile(tid0):
        return m.read_png(os.path.join(args.hd, "7_%04d.png" % (tid0 + 1)))

    def mask_alpha(tid0):
        # mkuPixel masks carry the value in the low byte (R), mkuAlpha (Gradient) in the real alpha
        w, h, rgba = sd[tid0 + 1]
        channel = 3 if tid0 >= GRADIENT_FIRST_ID else 0
        return w, h, bytes(rgba[i * 4 + channel] for i in range(w * h))

    def save(name, img):
        m.write_png(os.path.join(args.out, name), *img)
        print("wrote %s (%dx%d)" % (name, img[0], img[1]))

    # 1. Hand-drawn transitions: the most common grass + one other terrain pair
    with open(args.tiles_json, encoding="utf-8-sig") as f:
        tiles = json.load(f)["Tiles"]
    by_pair = {}
    for t in tiles:
        kinds = set(t.get("CornersTerKinds", []))
        if len(kinds) == 2 and "tkGrass" in kinds:
            by_pair.setdefault(frozenset(kinds), []).append(t["ID"])
    pair, ids = max(by_pair.items(), key=lambda kv: len(kv[1]))
    ids = ids[:HANDDRAWN_SAMPLES]
    print("hand-drawn %s tiles: %s" % (" / ".join(sorted(k[2:] for k in pair)), ids))
    sd_px = sd[ids[0] + 1][0]
    save("1_handdrawn_sd.png", sheet([nearest(*sd[t + 1], 8) for t in ids]))
    save("1_handdrawn_hd.png", sheet([nearest(*hd_tile(t), max(1, 8 * sd_px // hd_tile(t)[0])) for t in ids]))

    # 2. The layer masks
    panels = []
    for first in MASK_FIRST_IDS:
        for k in range(4):
            w, h, a = mask_alpha(first + k)
            panels.append(nearest(w, h, grey(a), 3))
    save("2_masks.png", sheet(panels, gap=6))

    # 3. One generated layer tile, three ways
    w, h, grass = sd[GRASS + 1]
    _, _, sand = sd[COAST_SAND + 1]
    _, _, a = mask_alpha(SOFT2_STRAIGHT)
    W, H, grass_hd = hd_tile(GRASS)
    _, _, sand_hd = hd_tile(COAST_SAND)
    scale = W // w
    a_nearest = nearest(w, h, grey(a), scale)[2][0::4]          # what GenerateTerrainTransitions used to do
    a_bilinear = m.upscale_bilinear(w, h, a, scale, channels=1)[2]
    save("3_layer.png", sheet([nearest(w, h, blend(w, h, grass, sand, a), 8),
                                nearest(W, H, blend(W, H, grass_hd, sand_hd, a_nearest), 8 // scale or 1),
                                nearest(W, H, blend(W, H, grass_hd, sand_hd, a_bilinear), 8 // scale or 1)]))


if __name__ == "__main__":
    main()
