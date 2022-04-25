echo called rx_pack.bat

REM build RXXPacker
msbuild ..\Utils\RXXPacker\RXXPacker.dproj /p:Configuration=Release /t:Build /clp:ErrorsOnly /fl /flp:LogFile="build_rxxpacker.log"
if errorlevel 1 goto exit3

@REM Backup local rxx files
@REM xcopy ..\data\Sprites ..\data\_Sprites\ /y /r /s
@REM Delete local rxx, they could contain wrong textures
@REM rmdir /S /Q ..\data\Sprites ..\dcu

REM Pack rx textures to rxx 
@REM call ..\Utils\RXXPacker\RXXPacker.exe gui guimain houses trees units
call ..\Utils\RXXPacker\RXXPacker.exe spritesBaseDir "%KMRResourcesRepoDir%" all
if errorlevel 1 goto exit3

goto exit0

:exit3
@echo off
exit /B 3

:exit0
@echo off
exit /B 0


