


REM build RXXPacker
msbuild ..\Utils\RXXPacker\RXXPacker.dproj /p:Configuration=Release /t:Build /clp:ErrorsOnly /fl /flp:LogFile="build_rxxpacker.log"

@REM Backup local rxx files
@REM xcopy ..\data\Sprites ..\data\_Sprites\ /y /r /s
@REM Delete local rxx, they could contain wrong textures
@REM rmdir /S /Q ..\data\Sprites ..\dcu

REM Pack rx textures to rxx 
@REM call ..\Utils\RXXPacker\RXXPacker.exe gui guimain houses trees units
call ..\Utils\RXXPacker\RXXPacker.exe all


