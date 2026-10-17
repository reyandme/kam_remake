### How to mod KaM Remake graphics

 * Run KaM Remake.
 * Press F11 in menu or in game.
 * Select Menu > Export Data > Resources > Units/Houses/Trees/etc.
 * Folder with exported graphics will be created `\KaM Remake\Export\`.
 * Now you can see all the the exported graphics and plan your mod.
 * Place the replacement graphics into the folder `\KaM Remake\Modding graphics\` preserving file names (e.g. `4_0003.png`). You can also add alpha shadow files, (f.e. `4_0003a.png`) and pivot points files (f.e `4_0003.txt`).  
Those files could be also placed into subfolders.  
If there are several sprites with the same name in the `Modding graphics` folder and its subfolders, then the game will load the one from `Modding graphics` folder, or from the first of subfolders in alphabetical order.  
Folders containing word 'skip' in their name will be ignored and any data from the will not be used. For example all files in the following subfolder will be skipped: `\KaM Remake\Modding graphics\my_mod\skip_units\`

`#_####.png` - main graphic
`#_####.txt` - offset information, 2 lines, X and Y offset in pixels
`#_####a.png` - player color mask area (gets processed)
`#_####m.png` - graphic mask or alpha (gets used 'as is')

 * When you restart the game the replacement graphic will be used.

### HD (high resolution) graphics

A replacement sprite may have more pixels than the original without changing its size in the game world:

 * **Derived scale**: if `#_####.png` is an exact integer multiple (2x, 3x, 4x, ...) of the original sprite's size in both axes, it is treated as an HD version of that sprite. The offset (pivot) is scaled automatically; a `#_####.txt` next to it is read in the PNG's own pixels.
 * **Explicit scale**: `#_####@4x.png` marks the sprite as 4x regardless of the original size. This is the only option for brand-new sprites that have no original to compare with. Companion files carry the same suffix: `#_####@4x.txt`, `#_####@4xa.png`, `#_####@4xm.png`.
 * A replacement whose size is not a uniform multiple of the original (and has no `@Nx` marker) is loaded at scale 1, i.e. the object itself changes size, as before. The log reports these.
 * HD sprites get linear texture filtering; the original ones keep the pixel look.

Don't put both `#_####.png` and `#_####@4x.png` for the same sprite into the folder.

Source: https://github.com/reyandme/kam_remake/wiki/Modding-graphics