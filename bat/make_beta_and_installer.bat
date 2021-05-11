@echo off

@REM Unset vars we use to determine multiple includes
@SET RS_INIT=False
@SET KAM_FOLDER_INIT=False

echo called make_beta_and_installer.bat
@REM we could use timer util made by https://www.gammadyne.com/cmdline.htm#timer

call timer.exe /nologo 

@REM or we could measure execution time in seconds via next calls
@REM @set /A _tic=%time:~0,2%*3600^+%time:~3,1%*10*60^+%time:~4,1%*60^+%time:~6,1%*10^+%time:~7,1% >nul

@REM let's use timecmd.bat to measure execution time 

@REM ##########################       CREATE BETA
call timecmd.bat create_beta.bat
if errorlevel 3 (goto exit3)

@REM @set /A _toc=%time:~0,2%*3600^+%time:~3,1%*10*60^+%time:~4,1%*60^+%time:~6,1%*10^+%time:~7,1% >nul
@REM @set /A _elapsed=%_toc%-%_tic
@REM @echo %_elapsed% seconds.

@REM echo Create Beta took:
@REM call "timer.exe" /nologo /r

echo ######                       Prepare for installer                   ######
call prepare_for_installer.bat > prepare_for_installer.log 2>&1

@echo #                                                                         # 
@echo #=========================================================================#
@echo #                            Start Inno Setup compilation                 #  
@echo #=========================================================================# 
@echo #  
@echo #

call timecmd.bat build_installer.bat
if errorlevel 3 (goto exit3)

@echo #
@echo #-------------------------------------------------------------------------#
@echo #                            Compilation completed !                      #  
@echo #-------------------------------------------------------------------------#

echo Total build time:
call "timer.exe" /nologo /S

goto exit0

:exit3
exit /B 3

:exit2
exit /B 2

:exit0
@echo off
exit /B 0
