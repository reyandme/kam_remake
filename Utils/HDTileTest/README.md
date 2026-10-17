# Making HD sprites with `make_hd_test_tiles.py`

The script reads the game's `data\Sprites\*.rxx` files and writes upscaled
PNGs into the `Modding graphics` folder, where the game picks them up at
startup. It needs nothing beyond Python 3 (no Pillow). Run every command from
the repository root.

## Basics

| Term | Meaning |
|---|---|
| RX number | file name prefix: `1` trees, `2` houses, `3` units, `4` GUI, `5` GUIMain, `7` tiles |
| source RXX | `data\Sprites\Trees_a.rxx`, `Houses_a.rxx`, `Units_a.rxx` (soft shadows baked in), `Tileset.rxx` for tiles |
| output folder | `Modding graphics\<name>\` – the game reads every subfolder except those with `skip` in their name |
| scale | always 4x (`--scale 4` is the default); the engine derives the scale from the image size |

Besides the main image the script writes the team colour mask
(`X_NNNNm.png`) where the sprite has one. Pivots need no files, the engine
rescales them.

## Route 1: bilinear (fastest, soft)

```
python Utils\HDTileTest\make_hd_test_tiles.py --rxx data\Sprites\Trees_a.rxx  --rx 1 --out "Modding graphics\hd_trees"
python Utils\HDTileTest\make_hd_test_tiles.py --rxx data\Sprites\Houses_a.rxx --rx 2 --out "Modding graphics\hd_houses"
python Utils\HDTileTest\make_hd_test_tiles.py --rxx data\Sprites\Units_a.rxx  --rx 3 --out "Modding graphics\hd_units"
python Utils\HDTileTest\make_hd_test_tiles.py                                        --out "Modding graphics\hd_tiles"
```

Trees and houses take under a minute, units (8696 sprites) about 3 minutes.
This is the recommended route for terrain; the others smear the grass
texture.

Tiles are not upscaled in isolation: a tile of one terrain kind wraps around
at its border, a transition tile gets a thin frame of the plain tile of the
terrain at each corner (`data\defines\tiles.json`, `CornersTerKinds`). Without
this every tile border stays a hard one-pixel step while the inside gets soft,
and the tile grid shows.
`--no-tile-context` gives the old behaviour.

## Route 2: xBR (crisp pixel-art edges, slow)

Same commands with `--filter xbr`:

```
python Utils\HDTileTest\make_hd_test_tiles.py --rxx data\Sprites\Houses_a.rxx --rx 2 --out "Modding graphics\hd_houses" --filter xbr
```

Pure Python, so slow: houses 10–15 minutes, units 30–40 minutes. Looks good
on units and houses, blotchy on foliage and grass.

## Route 3: Real-ESRGAN (best quality, external tool)

Binary: `realesrgan-ncnn-vulkan.exe` from the `realesrgan-ncnn-vulkan-*-windows.zip`
release of GitHub `xinntao/Real-ESRGAN`. The examples below assume it was
extracted to `%USERPROFILE%\Downloads\realesrgan-ncnn-vulkan`.

1. Export the sprites at original size (with colour bleed, which matters for
   the edges):
   ```
   python Utils\HDTileTest\make_hd_test_tiles.py --rxx data\Sprites\Houses_a.rxx --rx 2 --export-sd Utils\HDTileTest\esrgan_in
   ```
2. Run the upscaler. The output folder must exist beforehand:
   ```
   mkdir Utils\HDTileTest\esrgan_out
   %USERPROFILE%\Downloads\realesrgan-ncnn-vulkan\realesrgan-ncnn-vulkan.exe -i Utils\HDTileTest\esrgan_in -o Utils\HDTileTest\esrgan_out -n realesrgan-x4plus-anime -s 4 -f png
   ```
   Model: `realesrgan-x4plus-anime` for houses and units, `realesrgan-x4plus`
   for trees. Neither is good for terrain.
3. Import the result (size check plus mask generation):
   ```
   python Utils\HDTileTest\make_hd_test_tiles.py --rxx data\Sprites\Houses_a.rxx --rx 2 --import-hd Utils\HDTileTest\esrgan_out --out "Modding graphics\hd_houses"
   ```

Empty the export/import folders between RX types, otherwise files of two
house sets would overwrite each other.

## Interpolated ("smooth animation") frames

The interpolated frames are not in the RXX files, they exist only in the
shipped `.rxa` packs as atlases (`Units.rxa` holds 63 198 sprites, 8 696 of
them base frames). `--rxa` cuts the sprites out of an `.rxa`; with
`--interp-only` it takes only the frames that are missing from `--rxx`:

```
python Utils\HDTileTest\make_hd_test_tiles.py --rxa data\Sprites\Trees.rxa  --rxx data\Sprites\Trees_a.rxx  --rx 1 --interp-only --out "Modding graphics\hd_trees_interp"
python Utils\HDTileTest\make_hd_test_tiles.py --rxa data\Sprites\Houses.rxa --rxx data\Sprites\Houses_a.rxx --rx 2 --interp-only --out "Modding graphics\hd_houses_interp"
```

These sprites have no original in the RXX the engine could derive the scale
from, so they are written as `1_0300@4x.png` with a `1_0300@4x.txt` pivot
file (and the hitbox lines for units); the engine and the packer read both.
`--filter`, `--export-sd` and `--import-hd` work the same way.

Mind the size: the unit frames are about 7x the base set (roughly 6 GB of
texture memory at 4x), which does not fit a 32-bit build. Use `--scale 2` for
them, or a 64-bit build of the game and the packer.

## One house at a time: context sheet for an image model

`make_house_sheet.py` collects every sprite that belongs to one house and writes three things:

```
python Utils\HDTileTest\make_house_sheet.py --house sawmill
```

- `house_sheets\sawmill\` – the individual sprites as PNG (alpha kept, colour bled). These are
  what you actually upscale.
- `house_sheets\sawmill_sheet.png` – all of them on one numbered grid, so an image model can see
  the whole building, its construction frame, the work animation, and the wares it consumes and
  produces in one go.
- `house_sheets\sawmill_masks.png` + `sawmill_manifest.txt` / `.json` – the masks separately (they
  are data, not art: build order on the big sprites, team colour on the small ones) and a text
  listing of what every cell is. Paste the manifest next to the image in the prompt; a model reads
  text far more reliably than labels rendered into pixels.

Sprite ids come from `data\defines\houses.dat` (the same record layout the engine reads) plus the
hardcoded snow sprites in `KM_ResHouses.pas`. `--list` prints the house names, `--with-fire` adds
the generic burning animation, `--cols` changes the grid width.

## Only a few sprites

`--only` takes 0-based ids, so `2_0142.png` is `--only 141`:

```
python Utils\HDTileTest\make_hd_test_tiles.py --rxx data\Sprites\Houses_a.rxx --rx 2 --only 141,0 --out "Modding graphics\probe"
```

When several folders contain the same sprite, the alphabetically first folder
wins.

## Trying it in the game

Start the game: the PNGs in `Modding graphics` are loaded at startup (about
35 s with the full unit set). To switch a folder off, rename it so that its
name contains `skip` (`hd_units_skip`).

## Finalising: native HD packs (fast loading)

Once you are happy, bake the PNGs into RXA packs, which load in about 10 s
instead of the 35 s the PNG route needs.

**Where the files live.** `data\Sprites` holds the stock (SD) packs and stays
untouched - an installation without HD is a vanilla game. The HD packs go into
**`data\Sprites\hd\`**, and the game loads them only when HD graphics are
switched on.

```
cd Utils\RXXPacker
RXXPacker.exe srx "..\..\data\Sprites\" hd "..\..\Modding graphics\" d "..\HDTileTest\hd_out\" rxa trees houses units tileset
cd ..\..
copy Utils\HDTileTest\hd_out\*.rxa "data\Sprites\hd\"
copy Utils\HDTileTest\hd_out\Tileset.rxx "data\Sprites\hd\"
```

`srx` is where the stock RXX files are read from, `hd` is the PNG folder tree
that gets applied on top of them, `d` is the output folder. Tiles have no RXA
(the game always loads the tileset from RXX), so `Tileset.rxx` is the tile
output. The packer must be built first from `Utils\RXXPacker\RXXPacker.dproj`.

Then rename the HD folders in `Modding graphics` to `skip`, otherwise the game
would apply the PNGs on top of the packs once more - slowly, and overwriting
what you just baked.

Switch it on in the game: **Options - Graphics - HD sprites**, or Ctrl+Shift+H
during a game. No restart, the switch loads the other set in a few seconds
(terrain included) and remembers the choice.

**Important:** the packer bakes exactly what `Modding graphics` would show at
that moment, alphabetical precedence included. A forgotten probe folder (for
example a single ESRGAN grass tile) can ruin the whole map, because the base
grass tile is also the source of every generated grass transition. Before
packing, check that only the folders you want to finalise are active:

```
Get-ChildItem "Modding graphics" -Directory | Where-Object { $_.Name -notmatch 'skip' }
```

To revert, delete `data\Sprites\hd\` (or just switch HD off in the options).
The stock files are never modified.

## Other switches

| Switch | Purpose |
|---|---|
| `--bleed N` | colour bleed into transparent pixels before upscaling (default 3, `0` disables); this is what removes the lilac fringe under linear filtering |
| `--no-masks` | do not write team colour masks |
| `--skip a,b,c` | keep these 0-based ids at the original resolution (e.g. tile transition masks 4949–4992) |
| `--max-id N` | only ids up to N (for a partial set) |
| `--mask-blur R` | blur tile transition masks (cosmetic experiment, not recommended) |
| `--tiles-json PATH` | corner terrain kinds for the tile context (default `data\defines\tiles.json`) |
| `--no-tile-context` | upscale every tile on its own with a clamped border (old behaviour, the tile grid shows) |

## Checking an HD tile set

Two helper scripts, both read the stock `data\Sprites\Tileset.rxx` and a folder
of HD tiles (`7_NNNN.png`). They check the two things that make HD terrain look
wrong: a visible tile grid and blocky transitions between terrain kinds.

```
python Utils\HDTileTest\measure_tile_seams.py     --hd "Modding graphics\hd_tiles_test_skip"
python Utils\HDTileTest\make_transition_panels.py --hd "Modding graphics\hd_tiles_test_skip" --out tile_panels
```

`measure_tile_seams.py` prints how much harder the step across a tile border
is than the steps inside a tile (median over the tiles). About 1 means no
visible grid. Add `--pure-only --max-id 600` to measure only the tiles of one
terrain kind: a transition tile laid next to itself is not a real
neighbourhood. On those the stock tiles give ~1.0, the old isolated bilinear
set ~4.4, the current one ~1.1.

`make_transition_panels.py` writes comparison images: hand-drawn transition
tiles in SD and HD, the 20 layer masks, and one generated layer tile with the
mask sampled nearest (the old engine) and bilinear (the engine now).
