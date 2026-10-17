"""
Unit tests for make_hd_test_tiles.py. Run from the repository root:
  python -m unittest Utils.HDTileTest.test_make_hd_test_tiles -v
or from this folder:
  python -m unittest test_make_hd_test_tiles -v

The RXX/RXA tests use the game data in data\\Sprites when it is present and are skipped otherwise.
"""
import os
import struct
import sys
import tempfile
import unittest
import zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_hd_test_tiles as m  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SPRITES = os.path.join(ROOT, "data", "Sprites")


def rgba(*pixels):
    return b"".join(bytes(p) for p in pixels)


class PngTests(unittest.TestCase):
    def test_write_read_roundtrip_rgba(self):
        w, h = 3, 2
        data = rgba((1, 2, 3, 255), (4, 5, 6, 0), (7, 8, 9, 128),
                    (10, 11, 12, 255), (13, 14, 15, 255), (16, 17, 18, 1))
        with tempfile.TemporaryDirectory() as d:
            p = os.path.join(d, "t.png")
            m.write_png(p, w, h, data)
            W, H, back = m.read_png(p)
        self.assertEqual((W, H), (w, h))
        self.assertEqual(back, data)

    def test_read_png_all_filter_types_and_color_types(self):
        # Hand-build PNGs with every scanline filter (0..4) and RGB / grey / grey+alpha colour types
        def build(w, h, ctype, channels, rows, filters):
            raw = b"".join(bytes([f]) + r for f, r in zip(filters, rows))
            def chunk(tag, payload):
                return struct.pack(">I", len(payload)) + tag + payload + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF)
            return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, ctype, 0, 0, 0))
                    + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))

        # RGB 2x5, each row uses a different filter; expected decoded rows below
        rows_plain = [bytes([10, 20, 30, 40, 50, 60]) for _ in range(5)]
        # Encode with filters: 0 none, 1 sub, 2 up, 3 average, 4 paeth
        enc = []
        prev = bytes(6)
        for y, row in enumerate(rows_plain):
            f = y
            out = bytearray(6)
            for i in range(6):
                a = row[i - 3] if i >= 3 else 0
                b = prev[i]
                c = prev[i - 3] if i >= 3 else 0
                if f == 0:
                    pred = 0
                elif f == 1:
                    pred = a
                elif f == 2:
                    pred = b
                elif f == 3:
                    pred = (a + b) >> 1
                else:
                    pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                    pred = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                out[i] = (row[i] - pred) & 0xFF
            enc.append(bytes(out))
            prev = row
        with tempfile.TemporaryDirectory() as d:
            p = os.path.join(d, "rgb.png")
            with open(p, "wb") as f:
                f.write(build(2, 5, 2, 3, enc, range(5)))
            W, H, out = m.read_png(p)
            self.assertEqual((W, H), (2, 5))
            self.assertEqual(out, b"".join(rgba((10, 20, 30, 255), (40, 50, 60, 255)) for _ in range(5)))

            p = os.path.join(d, "grey.png")
            with open(p, "wb") as f:
                f.write(build(2, 1, 0, 1, [bytes([7, 9])], [0]))
            self.assertEqual(m.read_png(p)[2], rgba((7, 7, 7, 255), (9, 9, 9, 255)))

            p = os.path.join(d, "ga.png")
            with open(p, "wb") as f:
                f.write(build(1, 1, 4, 2, [bytes([7, 100])], [0]))
            self.assertEqual(m.read_png(p)[2], rgba((7, 7, 7, 100)))

    def test_read_png_rejects_16bit(self):
        with tempfile.TemporaryDirectory() as d:
            p = os.path.join(d, "bad.png")
            with open(p, "wb") as f:
                ihdr = struct.pack(">IIBBBBB", 1, 1, 16, 6, 0, 0, 0)
                f.write(b"\x89PNG\r\n\x1a\n" + struct.pack(">I", 13) + b"IHDR" + ihdr + b"\0\0\0\0")
            with self.assertRaises(SystemExit):
                m.read_png(p)


class UpscaleTests(unittest.TestCase):
    def test_bilinear_constant_image_stays_constant(self):
        w, h = 3, 2
        data = rgba(*[(50, 100, 150, 255)] * (w * h))
        W, H, out = m.upscale_bilinear(w, h, data, 4)
        self.assertEqual((W, H), (12, 8))
        self.assertEqual(out, rgba(*[(50, 100, 150, 255)] * (W * H)))

    def test_bilinear_edge_pixels_keep_source_value(self):
        # 2x1 black/white: leftmost and rightmost output pixels keep the source values, the middle blends
        data = rgba((0, 0, 0, 255), (255, 255, 255, 255))
        W, H, out = m.upscale_bilinear(2, 1, data, 4)
        self.assertEqual((W, H), (8, 4))
        self.assertEqual(out[0:3], b"\x00\x00\x00")
        self.assertEqual(out[7 * 4:7 * 4 + 3], b"\xff\xff\xff")
        mid = out[3 * 4]
        self.assertTrue(0 < mid < 255)
        # symmetric around the centre
        self.assertEqual(out[3 * 4], 255 - out[4 * 4])

    def test_bilinear_single_channel(self):
        W, H, out = m.upscale_bilinear(2, 2, bytes([0, 0, 255, 255]), 2, channels=1)
        self.assertEqual((W, H), (4, 4))
        self.assertEqual(out[0], 0)
        self.assertEqual(out[15], 255)

    def test_axis_table_covers_source_range(self):
        tab = m._axis_table(5, 4)
        self.assertEqual(len(tab), 20)
        self.assertEqual((tab[0][0], tab[0][2]), (0, 0), "first output pixel is the first source pixel with full weight")
        self.assertEqual(tab[-1][0], 4)
        self.assertEqual(tab[-1][1], 4, "last output pixel never reads past the source")
        self.assertTrue(all(0 <= wt <= 256 for _, _, wt in tab))

    def test_xbr_scales_and_keeps_flat_areas(self):
        w, h = 4, 4
        data = rgba(*[(10, 200, 30, 255)] * (w * h))
        W, H, out = m.upscale_xbr(w, h, data, 4)
        self.assertEqual((W, H), (16, 16))
        self.assertEqual(out, rgba(*[(10, 200, 30, 255)] * (W * H)))

    def test_xbr_rejects_non_power_of_two(self):
        with self.assertRaises(SystemExit):
            m.upscale_xbr(2, 2, bytes(16), 3)

    def test_xbr_diagonal_edge_gets_blended(self):
        # A hard diagonal (top-left black triangle on white) must produce intermediate values along the edge
        w = h = 6
        px = []
        for y in range(h):
            for x in range(w):
                px.append((0, 0, 0, 255) if x + y < 6 else (255, 255, 255, 255))
        W, H, out = m.xbr2x(w, h, rgba(*px))
        values = set(out[0::4])
        self.assertIn(0, values)
        self.assertIn(255, values)
        self.assertTrue(any(0 < v < 255 for v in values), "no blended pixels along the diagonal")


class TileContextTests(unittest.TestCase):
    """upscale_tile: the tile border must be as soft as the inside."""
    GREY, GREEN, YELLOW = (128, 128, 128, 255), (0, 200, 0, 255), (250, 220, 0, 255)
    N = 4

    def solid(self, px):
        return (self.N, self.N, rgba(*[px] * (self.N * self.N)), None)

    def sprites(self):
        # 1-based ids: plain grass is tile 0, plain coast sand tile 32, the transition under test tile 70
        return {m.BASE_TILE["tkGrass"] + 1: self.solid(self.GREEN),
                m.BASE_TILE["tkCoastSand"] + 1: self.solid(self.YELLOW),
                71: self.solid(self.GREY)}

    def test_wrap_axis_table_reads_the_opposite_edge(self):
        tab = m._axis_table(5, 4, wrap=True)
        self.assertEqual(len(tab), 20)
        self.assertEqual(tab[0][:2], (4, 0), "first output pixel blends the last and the first source pixel")
        self.assertEqual(tab[-1][:2], (4, 0), "last output pixel blends the last and the first source pixel")

    def test_wrap_blends_the_border_with_the_opposite_edge(self):
        W, H, out = m.upscale_bilinear(2, 1, rgba((0, 0, 0, 255), (255, 255, 255, 255)), 4, wrap=True)
        self.assertTrue(0 < out[0] < 255, "clamped would keep pure black here")
        self.assertTrue(0 < out[(W - 1) * 4] < 255, "clamped would keep pure white here")

    def test_pure_tile_is_wrapped(self):
        corners = {0: ["tkGrass"] * 4}
        *_, how = m.upscale_tile(0, self.N, self.N, self.solid(self.GREEN)[2], 4, corners, self.sprites())
        self.assertEqual(how, "wrap")

    def test_transition_tile_blends_into_the_terrain_at_its_corners(self):
        corners = {70: ["tkCoastSand", "tkCoastSand", "tkGrass", "tkGrass"]}  # sand on top, grass below
        W, H, out, how = m.upscale_tile(70, self.N, self.N, self.solid(self.GREY)[2], 4, corners, self.sprites())
        self.assertEqual(how, "context")
        self.assertEqual((W, H), (16, 16))
        top, bottom, middle = out[8 * 4:8 * 4 + 4], out[(15 * W + 8) * 4:(15 * W + 8) * 4 + 4], out[(8 * W + 8) * 4:(8 * W + 8) * 4 + 4]
        self.assertEqual(tuple(middle), self.GREY, "the inside stays the tile itself")
        self.assertGreater(top[0], self.GREY[0], "the top border leans towards the yellow sand above")
        self.assertGreater(bottom[1], self.GREY[1], "the bottom border leans towards the green grass below")

    def test_tiles_without_usable_context_stay_clamped(self):
        sprites = self.sprites()
        grey = self.solid(self.GREY)[2]
        for tile0, corners in ((70, {}),                                           # not in tiles.json
                               (70, {70: ["tkCustom", "tkGrass", "tkGrass", "tkGrass"]}),  # custom corner
                               (4949, {4949: ["tkGrass", "tkGrass", "tkSand", "tkSand"]})):  # a layer mask
            *_, how = m.upscale_tile(tile0, self.N, self.N, grey, 4, corners, sprites)
            self.assertEqual(how, "clamp", "tile %d" % tile0)


class BleedTests(unittest.TestCase):
    def test_bleed_fills_transparent_neighbours_only(self):
        # 3x1: opaque red | transparent lilac | transparent lilac
        data = rgba((255, 0, 0, 255), (107, 107, 175, 0), (107, 107, 175, 0))
        out = m.bleed_colors(3, 1, data, 1)
        self.assertEqual(out[0:4], bytes((255, 0, 0, 255)))
        self.assertEqual(out[4:8], bytes((255, 0, 0, 0)), "first pass reaches the direct neighbour, alpha stays 0")
        self.assertEqual(out[8:12], bytes((107, 107, 175, 0)), "one pass does not reach two pixels away")
        out2 = m.bleed_colors(3, 1, data, 2)
        self.assertEqual(out2[8:12], bytes((255, 0, 0, 0)), "second pass reaches it")

    def test_bleed_averages_several_neighbours(self):
        data = rgba((100, 0, 0, 255), (0, 0, 0, 0), (0, 200, 0, 255))
        out = m.bleed_colors(3, 1, data, 1)
        self.assertEqual(out[4:8], bytes((50, 100, 0, 0)))

    def test_bleed_zero_passes_is_identity(self):
        data = rgba((1, 2, 3, 0), (4, 5, 6, 255))
        self.assertEqual(m.bleed_colors(2, 1, data, 0), data)


class MaskTests(unittest.TestCase):
    def test_mask_to_rgba(self):
        out = m.mask_to_rgba(bytes([0, 128, 255]))
        self.assertEqual(out, rgba((0, 0, 0, 255), (128, 128, 128, 255), (255, 255, 255, 255)))


@unittest.skipUnless(os.path.exists(os.path.join(SPRITES, "Trees_a.rxx")), "game data not present")
class GameDataTests(unittest.TestCase):
    def test_rxx_trees(self):
        s = m.read_rxx(os.path.join(SPRITES, "Trees_a.rxx"), with_masks=True)
        self.assertGreater(len(s), 200)
        w, h, px, mask = s[min(s)]
        self.assertEqual(len(px), w * h * 4)
        self.assertIsNone(mask, "trees carry no team colour masks")

    @unittest.skipUnless(os.path.exists(os.path.join(SPRITES, "Units_a.rxx")), "Units_a.rxx missing")
    def test_rxx_units_needs_units_flag(self):
        s = m.read_rxx(os.path.join(SPRITES, "Units_a.rxx"), with_masks=True, units=True)
        self.assertGreater(len(s), 8000)
        self.assertTrue(any(v[3] is not None for v in s.values()), "units have team colour masks")

    @unittest.skipUnless(os.path.exists(os.path.join(SPRITES, "_rxa_disabled", "Trees.rxa")), "shipped Trees.rxa missing")
    def test_rxa_matches_rxx_for_base_sprites(self):
        rxa = m.read_rxa(os.path.join(SPRITES, "_rxa_disabled", "Trees.rxa"))
        rxx = m.read_rxx(os.path.join(SPRITES, "Trees_a.rxx"), with_masks=True)
        self.assertGreater(len(rxa), len(rxx), "RXA also holds the interpolated frames")
        for sid, (w, h, px, mask) in rxx.items():
            self.assertIn(sid, rxa)
            aw, ah, apx, amask, pivot, sns = rxa[sid]
            self.assertEqual((aw, ah), (w, h))
            self.assertEqual(apx, px, "sprite %d pixels differ" % sid)
            self.assertIsNone(sns)
            self.assertEqual(len(pivot), 2)


if __name__ == "__main__":
    unittest.main()
