"""
Measure how visible the tile grid is in an HD tile set.

Every tile is laid next to itself (right edge against left edge, bottom against top), which is how a
field of one terrain kind looks. For each tile the mean brightness step across that border is divided
by the mean step between neighbouring pixels inside the tile, and the median over all tiles is printed:
  ~1   the border is as soft as the inside - no visible grid (stock SD tiles give ~1.2)
  >>1  the border is much harder than the inside - the grid shows (clamped bilinear 4x gives ~5.8)

It also prints what the same upscale gives when the tile wraps around at its border instead of
clamping, as a reference for the fix.

Usage (from the repository root):
  python Utils\\HDTileTest\\measure_tile_seams.py --hd "Modding graphics\\hd_tiles_test_skip"
"""
import argparse
import os
import statistics
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_hd_test_tiles as m  # noqa: E402

SD_TILE_PX = 32


def luminance_rows(w, h, rgba):
    return [[0.299 * rgba[i] + 0.587 * rgba[i + 1] + 0.114 * rgba[i + 2]
             for i in range(y * w * 4, (y + 1) * w * 4, 4)] for y in range(h)]


def seam_ratio(w, h, rgba):
    """Border step / inner step for the tile placed next to itself. None if the tile is flat."""
    lum = luminance_rows(w, h, rgba)
    inner = [abs(lum[y][x + 1] - lum[y][x]) for y in range(h) for x in range(w - 1)]
    inner += [abs(lum[y + 1][x] - lum[y][x]) for y in range(h - 1) for x in range(w)]
    seam = [abs(lum[y][0] - lum[y][w - 1]) for y in range(h)]
    seam += [abs(lum[0][x] - lum[h - 1][x]) for x in range(w)]
    inner_mean = statistics.mean(inner)
    return statistics.mean(seam) / inner_mean if inner_mean else None


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--sd", default=os.path.join("data", "Sprites", "Tileset.rxx"), help="stock tileset RXX")
    ap.add_argument("--hd", required=True, help="folder with the HD tiles as 7_NNNN.png")
    ap.add_argument("--max-id", type=int, default=250, help="measure tiles 1..N (1-based, as in the file names)")
    ap.add_argument("--scale", type=int, default=4, help="scale for the wrap-around reference")
    ap.add_argument("--pure-only", action="store_true",
                    help="only tiles of one terrain kind (tiles.json). Laying a transition tile next to itself is not "
                         "a real neighbourhood, so the ratio only means something for these")
    ap.add_argument("--tiles-json", default=os.path.join("data", "defines", "tiles.json"))
    args = ap.parse_args()

    pure = None
    if args.pure_only:
        pure = {tile0 for tile0, kinds in m.load_tile_corners(args.tiles_json).items()
                if len(set(kinds)) == 1 and kinds[0] != "tkCustom"}

    sd = m.read_rxx(args.sd)
    sd_ratios, hd_ratios, wrap_ratios = [], [], []
    for sid in range(1, args.max_id + 1):
        png = os.path.join(args.hd, "7_%04d.png" % sid)
        if sid not in sd or not os.path.exists(png):
            continue
        if pure is not None and sid - 1 not in pure:
            continue
        w, h, rgba = sd[sid]
        if (w, h) != (SD_TILE_PX, SD_TILE_PX):
            continue
        sd_r = seam_ratio(w, h, rgba)
        hd_r = seam_ratio(*m.read_png(png))
        if sd_r is None or hd_r is None:
            continue
        sd_ratios.append(sd_r)
        hd_ratios.append(hd_r)
        wrap_ratios.append(seam_ratio(*m.upscale_bilinear(w, h, rgba, args.scale, wrap=True)))

    if not hd_ratios:
        raise SystemExit("No tile could be measured - check --hd")

    print("tiles measured: %d" % len(hd_ratios))
    print("border / inner step, median:")
    print("  SD (stock)                  %.2f" % statistics.median(sd_ratios))
    print("  HD (%s)  %.2f" % (args.hd, statistics.median(hd_ratios)))
    print("  bilinear x%d, wrap-around    %.2f" % (args.scale, statistics.median(wrap_ratios)))


if __name__ == "__main__":
    main()
