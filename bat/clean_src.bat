call rsvars.bat

@echo off
@REM Delete folders recursively
@REM Its easier to delete folder recursively from project root folder
cd ..

FOR /D /R %%X IN (__history) DO RD /S /Q "%%X"
FOR /D /R %%X IN (__recovery) DO RD /S /Q "%%X"
FOR /D /R %%X IN (backup) DO RD /S /Q "%%X"

rmdir /S /Q logs dcu
if %IncludeScriptingEditor%==True (
rmdir /S /Q "%ScriptingEditorDir%"\bin\SE_Data\Logs
)

erase /F /Q /S *.~* *.ddp *.drc *.dcp *.dcu
erase /F /Q /S *.o *.or *.ppu *.compiled *.local
erase /F /Q /S *.tmp *.log thumbs.db KaM_Remake.map descript.ion *.skincfg *.identcache *.tvsconfig *.mi *.LOG.txt *.stat bugreport.txt *.bak

erase /F /Q /S /A:H *.~* *.ddp *.drc *.dcp *.dcu
erase /F /Q /S /A:H *.o *.or *.ppu *.compiled *.local
erase /F /Q /S /A:H *.tmp *.log thumbs.db KaM_Remake.map descript.ion *.skincfg *.identcache *.tvsconfig *.mi *.LOG.txt *.stat bugreport.txt *.bak

erase /F /Q /S Maps\*.rar Maps\*.zip Maps\*.7z MapsMP\*.rar MapsMP\*.zip MapsMP\*.7z

REM clean all empty dirs, f.e. old/renamed maps
ROBOCOPY . . /S /MOVE

cd bat
