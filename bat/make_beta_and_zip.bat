@echo off
echo called make_beta_and_zip.bat

@REM Unset vars we use to determine multiple includes
@SET RS_INIT=False
@SET KAM_FOLDER_INIT=False

call timecmd.bat create_beta.bat
if errorlevel 3 (goto exit3)

REM Archive into 7z
call timecmd.bat 7zip.bat
if errorlevel 3 (goto exit3)

goto exit0

:exit3
exit /B 3

:exit0
@echo off
exit /B 0
