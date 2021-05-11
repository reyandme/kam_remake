@echo off

echo called create_beta.bat
@REM echo ######                       create_beta.bat                         ######
call get_kam_folder.bat

if errorlevel 2 (goto exit2)

@SET kam_folder=%build_full_kmr_dir%

call create.bat
if errorlevel 3 (goto exit3)

echo ######                       create beta Done                        ######
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