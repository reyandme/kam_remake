@echo off
echo called create_beta.bat

@SET RS_INIT=False
@SET KAM_FOLDER_INIT=False
@SET UPDATE_REV=False

@REM Prepare Build
echo ######                       Prepare build                           ######
call prepare_build.bat > prepare_build.log 2>&1
if errorlevel 3 (goto exit3)

echo KMR Beta Revision: r%kam_revision%

@echo off
call get_kam_folder.bat > get_kam_folder.log 2>&1

if errorlevel 2 (goto exit2)

@SET kam_folder=%build_full_kmr_dir%

echo KMR Beta Folder: %kam_folder%

call create.bat
if errorlevel 3 (goto exit3)

echo ######                       Create Beta Done                        ######
goto exit0

:exit3
@echo off
exit /B 3 

:exit2
@echo off
exit /B 2

:exit0
@echo off
exit /B 0