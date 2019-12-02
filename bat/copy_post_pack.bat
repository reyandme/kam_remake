
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
xcopy ..\data\gfx "%kam_folder%"\data\gfx\ /y /r /s
xcopy ..\data\Sprites "%kam_folder%"\data\Sprites\ /y /r /s
xcopy ..\data\text "%kam_folder%"\data\text\ /y /r /s
xcopy ..\data\locales.txt "%kam_folder%"\data\locales.txt* /y /r /i
xcopy ..\Campaigns "%kam_folder%"\Campaigns\ /y /r /s
xcopy ..\Maps "%kam_folder%"\Maps\ /y /r /s /exclude:excluded_test_maps.txt
xcopy ..\MapsMP "%kam_folder%"\MapsMP\ /y /r /s
xcopy ..\Tutorials "%kam_folder%"\Tutorials\ /y /r /s
xcopy ..\Sounds "%kam_folder%"\Sounds\ /y /r /s
xcopy ..\Music "%kam_folder%"\Music\ /y /r /s
xcopy ..\Readme "%kam_folder%"\ /y /r /s

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
xcopy ..\KM_TextIDs.inc "%kam_folder%"\KM_TextIDs.inc* /y /r /i
xcopy ..\libzplay.dll "%kam_folder%"\libzplay.dll* /y /r /i
xcopy ..\ogg.dll "%kam_folder%"\ogg.dll* /y /r /i
xcopy ..\vorbis.dll "%kam_folder%"\vorbis.dll* /y /r /i
xcopy ..\vorbisfile.dll "%kam_folder%"\vorbisfile.dll* /y /r /i
xcopy "%KMRPrevVersionDir%"\oalinst.exe "%kam_folder%"\oalinst.exe* /y /r /i

@REM copy ScriptingEditor
if %IncludeScriptingEditor%==True (
xcopy "%ScriptingEditorDir%"\bin\ScriptingEditor.exe* "%kam_folder%"\ScriptingEditor /y /r /i
xcopy "%ScriptingEditorDir%"\bin\SE_Data "%kam_folder%"\ScriptingEditor\SE_Data\ /y /r /s
xcopy "..\Utils\ScriptValidator\ScriptValidator.exe" "%kam_folder%"\ScriptingEditor\SE_Data\KMR\ScriptValidator.exe* /y /r /i
@REM no need for KP folder
rmdir /S /Q "%ScriptingEditorDir%"\bin\SE_Data\KP
)


@REM copy utility applications exe files
xcopy "..\Utils\Campaign builder\KaM_Remake_Settings_ini_readme.txt" "%kam_folder%"\KaM_Remake_Settings_ini_readme.txt* /y /r /i
xcopy "..\Utils\Campaign builder\CampaignBuilder.exe" "%kam_folder%"\CampaignBuilder.exe* /y /r /i
xcopy "..\Utils\DedicatedServer\KaM_DedicatedServer.exe" "%kam_folder%"\KaM_Remake_Server_win32.exe* /y /r /i
xcopy "..\Utils\DedicatedServerGUI\KaM_DedicatedServerGUI.exe" "%kam_folder%"\KaM_Remake_ServerGUI_win32.exe* /y /r /i
xcopy "..\Utils\ScriptValidator\ScriptValidator.exe" "%kam_folder%"\ScriptValidator.exe* /y /r /i
xcopy "..\Utils\TranslationManager\TranslationManager.exe" "%kam_folder%"\TranslationManager.exe* /y /r /i
@REM copy linux dedicated servers
xcopy "..\Utils\DedicatedServer\KaM_Remake_Server_linux_x86" "%kam_folder%"\KaM_Remake_Server_linux_x86* /y /r /i
xcopy "..\Utils\DedicatedServer\KaM_Remake_Server_linux_x86_64" "%kam_folder%"\KaM_Remake_Server_linux_x86_64* /y /r /i
