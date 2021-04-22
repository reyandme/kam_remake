
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
xcopy ..\data\gfx "%kam_folder%"\data\gfx\ /y /r /s
xcopy ..\data\Sprites "%kam_folder%"\data\Sprites\ /y /r /s
xcopy ..\data\text "%kam_folder%"\data\text\ /y /r /s
xcopy ..\data\locales.txt "%kam_folder%"\data\locales.txt* /y /r /i
xcopy ..\Campaigns "%kam_folder%"\Campaigns\ /y /r /s
xcopy ..\Maps "%kam_folder%"\Maps\ /y /r /s /exclude:excluded_test_maps.txt
xcopy ..\MapsMP "%kam_folder%"\MapsMP\ /y /r /s
xcopy ..\Tutorials "%kam_folder%"\Tutorials\ /y /r /s
xcopy ..\Docs\Readme "%kam_folder%"\ /y /r /s
xcopy ..\Sounds "%kam_folder%"\Sounds\ /y /r /s
xcopy ..\Music "%kam_folder%"\Music\ /y /r /s
xcopy ..\lib "%kam_folder%"\lib\ /y /r /s
xcopy ..\"Modding graphics" "%kam_folder%"\"Modding graphics"\ /y /r /s


REM ============================================================
REM Copy video files
REM ============================================================
xcopy "%KMRVideosDir%" "%kam_folder%" /y /r /s

REM ============================================================
REM Copy files from KMRPrevVersionDir
REM ============================================================
xcopy "%KMRPrevVersionDir%"\data\sfx "%kam_folder%"\data\sfx\ /y /r /s
xcopy "%KMRPrevVersionDir%"\Music "%kam_folder%"\Music\ /y /r /s
xcopy "%KMRPrevVersionDir%"\Campaigns\*.mp3 "%kam_folder%"\Campaigns\ /y /r /s


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
xcopy "%KMRPrevVersionDir%"\oalinst.exe "%kam_folder%"\oalinst.exe* /y /r /i

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
xcopy "..\Utils\Campaign builder\KaM_Remake_Settings_ini_readme.txt" "%kam_folder%"\Utils\KaM_Remake_Settings_ini_readme.txt* /y /r /i
xcopy "..\Utils\Campaign builder\CampaignBuilder.exe" "%kam_folder%"\Utils\CampaignBuilder.exe* /y /r /i
xcopy "..\Utils\DedicatedServer\KaM_DedicatedServer.exe" "%kam_folder%"\Utils\KaM_Remake_Server_win32.exe* /y /r /i
xcopy "..\Utils\DedicatedServerGUI\KaM_DedicatedServerGUI.exe" "%kam_folder%"\Utils\KaM_Remake_ServerGUI_win32.exe* /y /r /i
xcopy "..\Utils\ScriptValidator\ScriptValidator.exe" "%kam_folder%"\Utils\ScriptValidator.exe* /y /r /i
xcopy "..\Utils\TranslationManager\TranslationManager.exe" "%kam_folder%"\Utils\TranslationManager.exe* /y /r /i
@REM copy linux dedicated servers
xcopy "..\Utils\DedicatedServer\KaM_Remake_Server_linux_x86" "%kam_folder%"\Utils\KaM_Remake_Server_linux_x86* /y /r /i
xcopy "..\Utils\DedicatedServer\KaM_Remake_Server_linux_x86_64" "%kam_folder%"\Utils\KaM_Remake_Server_linux_x86_64* /y /r /i
