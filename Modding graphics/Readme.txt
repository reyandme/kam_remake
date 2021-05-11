How to mod KaM Remake graphics

Run the KaM Remake.

Press F11 in menu or in game.

Select Menu > Export > Units/houses/Trees/etc.

Folder with exported graphics will be created \KaM Remake\Export\.

Now you can see all the the exported graphics and plan your mod.

Place the replacement graphics into this folder (\KaM Remake\Modding graphics\) preserving file names (e.g. 4_0003.png). You can also add alpha shadow files, (f.e. 4_0003a.png) and pivot points files (f.e 4_0003.txt).
Those files could be also placed into subdirectories. 
If there are several sprites with the same name in the Modding graphics folder and subdirectories, then game will load one from Modding graphics folder, if file exists, or from the first of subdirectories in alphabetical order.
Files with string 'skip' in their relative path will be ignored and not loaded. F.e. all files in next subdirectory will be skipped: \KaM Remake\Modding graphics\my_mod\skip_units\

#_####.png - main graphic
#_####.txt - offset information, 2 lines, X and Y offset in pixels
#_####a.png - player color mask area

When you restart the game the replacement graphic will be used.

https://github.com/reyandme/kam_remake/wiki/Modding-graphics
