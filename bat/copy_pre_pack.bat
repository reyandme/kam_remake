echo called copy_pre_pack.bat

REM Copy rx resorces from original game
xcopy "%KMRPrivateRepoDir%\SpriteResource\*.rx" "%KMRResourcesRepoDir%\SpriteResource\" /y /r /s
REM copy palette files
xcopy "%KMRPrivateRepoDir%\data\gfx\*" "..\data\gfx\" /y /r /s

mkdir ..\data\defines

REM Copy data files from original KaM TPR game
xcopy "%KaMOrigDir%\data\defines\houses.dat" ..\data\defines\houses.dat* /y /r /i
xcopy "%KaMOrigDir%\data\defines\unit.dat" ..\data\defines\unit.dat* /y /r /i
