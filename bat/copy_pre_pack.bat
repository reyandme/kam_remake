REM Copy rx resorces from original game
xcopy "%KaMDir%\data\gfx\res" ..\SpriteResource\ /y /r /s
xcopy "%KaMDir%\data\gfx\*" ..\data\gfx /y /r 

mkdir ..\data\defines

REM Copy data files from original KaM TPR game
xcopy "%KaMDir%\data\defines\*.dat" ..\data\defines /y /r /s