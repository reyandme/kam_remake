@echo off
echo called copy_post_pack.bat

@REM ============================================================
@REM Copy music files from original KaM TPR game
@REM ============================================================
@REM take music from previous KMR version for now
@REM xcopy "%KaMOrigDir%"\data\sfx\songs\*.sng "%kam_folder%"\Music\*.mp2 /y /r /s


REM ============================================================
REM Copy data folders
REM ============================================================
@REM Copy all data files, except sfx, which should be copied from KMRPrevVersionDir
xcopy ..\data\defines "%kam_folder%"\data\defines\ /y /r /s
xcopy ..\data\cursors "%kam_folder%"\data\cursors\ /y /r /s
REM xcopy ..\data\gfx "%kam_folder%"\data\gfx\ /y /r /s
@REM Copy *.rxx files only from the /data/Sprites folder, since we will copy *.rxa from the KMR private repo
REM xcopy ..\data\Sprites\*.rxx "%kam_folder%"\data\Sprites\ /y /r /s 
REM xcopy ..\data\Sprites\*.rxa "%kam_folder%"\data\Sprites\ /y /r /s 
xcopy ..\data\text "%kam_folder%"\data\text\ /y /r /s
xcopy ..\data\locales.txt "%kam_folder%"\data\locales.txt* /y /r /i
xcopy "..\Docs\Readme\Readme" "%kam_folder%"\Readme\ /y /r /s
xcopy "..\Docs\Readme\Readme_eng.html" "%kam_folder%"\Readme_eng.html* /y /r /i
xcopy "..\Docs\Readme\Readme_ger.html" "%kam_folder%"\Readme_ger.html* /y /r /i
xcopy "..\Docs\Readme\Readme_pol.html" "%kam_folder%"\Readme_pol.html* /y /r /i
xcopy "..\Docs\Readme\Readme_rus.html" "%kam_folder%"\Readme_rus.html* /y /r /i
xcopy ..\Sounds "%kam_folder%"\Sounds\ /y /r /s
xcopy ..\Music "%kam_folder%"\Music\ /y /r /s
xcopy ..\lib "%kam_folder%"\lib\ /y /r /s
xcopy ..\"Modding graphics"\Readme.txt "%kam_folder%"\"Modding graphics"\Readme.txt* /y /r /s


REM ============================================================
REM Copy *.rxa resource files 
REM ============================================================
REM xcopy "%SpritesRXADir%"\*.rxa "%kam_folder%"\data\Sprites\ /y /r /s


call pull_maps.bat

REM ============================================================
REM Copy Maps, Campaigns and Tutorials
REM ============================================================
xcopy "%KMRMapsRepoDir%"\Campaigns "%kam_folder%"\Campaigns\ /y /r /s
xcopy "%KMRMapsRepoDir%"\Maps "%kam_folder%"\Maps\ /y /r /s
xcopy "%KMRMapsRepoDir%"\MapsMP "%kam_folder%"\MapsMP\ /y /r /s
xcopy "%KMRMapsRepoDir%"\Tutorials "%kam_folder%"\Tutorials\ /y /r /s



REM ============================================================
REM Copy video files
REM ============================================================
xcopy "%KMRPrivateRepoDir%"\Video "%kam_folder%" /y /r /s
REM copy fonts
xcopy "%KMRPrivateRepoDir%"\data "%kam_folder%"\data\ /y /r /s

REM ============================================================
REM Copy files from KMRPrevVersionDir
REM ============================================================
xcopy "%KMRPrevVersionDir%"\data\sfx "%kam_folder%"\data\sfx\ /y /r /s
xcopy "%KMRPrevVersionDir%"\Music "%kam_folder%"\Music\ /y /r /s
xcopy "%KMRPrevVersionDir%"\Campaigns\*.mp3 "%kam_folder%"\Campaigns\ /y /r /s

@echo off
setlocal

REM Delete all count.dat files from sfx folders recursively, they are temp game files 
for /r "%kam_folder%"\data\sfx\ %%f in ("count.dat") do (
    del "%%f"
)

endlocal


@REM ============================================================
@REM Erase source-code files from copied "data\"
@REM ============================================================
@REM erase /F /Q /S .\"%kam_folder%"\*.inc


REM ============================================================
REM Copy selected executable files
REM ============================================================
@REM Adding * to the file name supresses the "Is it a file or a folder" query
@REM xcopy ..\data.pack .\"%kam_folder%"\data.pack* /y /r /i
xcopy ..\KaM_Remake.exe "%kam_folder%"\KaM_Remake.exe* /y /r /i
REM xcopy ..\libzplay.dll "%kam_folder%"\libzplay.dll* /y /r /i
xcopy ..\bass.dll "%kam_folder%"\bass.dll* /y /r /i
xcopy ..\ogg.dll "%kam_folder%"\ogg.dll* /y /r /i
xcopy ..\vorbis.dll "%kam_folder%"\vorbis.dll* /y /r /i
xcopy ..\vorbisfile.dll "%kam_folder%"\vorbisfile.dll* /y /r /i
xcopy ..\Utils\AVIPlayer\OpenAL32.dll "%kam_folder%"\OpenAL32.dll* /y /r /i
xcopy ..\Installer\uninst_clean.bat "%kam_folder%"\uninst_clean.bat* /y /r /i
xcopy ..\Installer\oalinst.exe "%kam_folder%"\oalinst.exe* /y /r /i

mkdir "%kam_folder%"\Utils

@REM copy ScriptingEditor
if %IncludeScriptingEditor%==True (
  xcopy "%ScriptingEditorDir%"\bin\ScriptingEditor.exe* "%kam_folder%"\Utils\ScriptingEditor /y /r /i
  xcopy "%ScriptingEditorDir%"\bin\SE_Data_KMR "%kam_folder%"\Utils\ScriptingEditor\SE_Data\ /y /r /s
  xcopy "%ScriptingEditorDir%"\bin\SE_Data\Examples "%kam_folder%"\Utils\ScriptingEditor\SE_Data\Examples\ /y /r /s
  xcopy "..\Utils\ScriptValidator\ScriptValidator.exe" "%kam_folder%"\Utils\ScriptingEditor\SE_Data\ScriptValidator.exe* /y /r /i
  REM erase "%kam_folder%"\Utils\ScriptingEditor\SE_Data\ScriptValidator.exe
  @REM no need for OLD and Logs folders there
  rmdir /S /Q "%kam_folder%"\Utils\ScriptingEditor\SE_Data\OLD
  rmdir /S /Q "%kam_folder%"\Utils\ScriptingEditor\SE_Data\Logs
)


@REM copy utility applications exe files
xcopy ..\KM_TextIDs.inc "%kam_folder%"\Utils\KM_TextIDs.inc* /y /r /i
xcopy "..\Utils\KaM_Remake_Settings_ini_readme.txt" "%kam_folder%"\Utils\KaM_Remake_Settings_ini_readme.txt* /y /r /i
xcopy "..\Utils\Campaign builder\CampaignBuilder.exe" "%kam_folder%"\Utils\CampaignBuilder.exe* /y /r /i
xcopy "..\Utils\DedicatedServer\KaM_DedicatedServer.exe" "%kam_folder%"\Utils\KaM_Remake_Server_win32.exe* /y /r /i
xcopy "..\Utils\DedicatedServerGUI\KaM_DedicatedServerGUI.exe" "%kam_folder%"\Utils\KaM_Remake_ServerGUI_win32.exe* /y /r /i
xcopy "..\Utils\ScriptValidator\ScriptValidator.exe" "%kam_folder%"\Utils\ScriptValidator.exe* /y /r /i
xcopy "..\Utils\TranslationManager (from kp-wiki)\TranslationManager.exe" "%kam_folder%"\Utils\TranslationManager.exe* /y /r /i
@REM copy linux dedicated servers
xcopy "..\Utils\DedicatedServer\KaM_Remake_Server_linux_x86" "%kam_folder%"\Utils\KaM_Remake_Server_linux_x86* /y /r /i
xcopy "..\Utils\DedicatedServer\KaM_Remake_Server_linux_x86_64" "%kam_folder%"\Utils\KaM_Remake_Server_linux_x86_64* /y /r /i
