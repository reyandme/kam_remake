echo called create.bat

REM ============================================================
REM Create new version package
REM ============================================================

REM Clean before build to avoid any side-effects from old DCUs
@REM echo ######                       create.bat                              ######
call get_kam_folder.bat

@echo off
if errorlevel 2 (goto exit2)

echo "%kam_folder%"

REM Clean target, so if anything fails we have a clear indication (dont pack old files by mistake)
echo ######                       Clean                                   ######
rmdir /S /Q "%kam_folder%" > clean.log 2>&1

REM Clean before build to avoid any side-effects from old DCUs
@call clean_src.bat >> clean.log 2>&1

REM Copy pre pack
echo ######                       Copy Pre Pack                           ######
call copy_pre_pack.bat > copy_pre_pack.log 2>&1

REM Pack rx data
echo ######                       RX Pack                                 ######
call rx_pack.bat > rx_pack.log 2>&1
if errorlevel 3 (goto exit3)

REM Build utility applications, included into the final build
echo ######                       Build utils                             ######
call build_utils.bat > build_utils.log 2>&1
if errorlevel 3 (goto exit3)

@REM Build exe
@REM call build_exe.bat
@REM if errorlevel 3 (goto exit3)

@REM Patch exe
@REM call patch_exe.bat

REM Copy post pack
echo ######                       Copy Post Pack                          ######
call copy_post_pack.bat > copy_post_pack.log 2>&1

@REM Restore local rxx
@REM call rxx_restore.bat

@REM Archive into 7z
@REM call 7zip.bat
@REM if errorlevel 3 (goto exit3)

@REM Create Installer instructions
@REM call prepare_installer.bat

@REM Build Installer
@REM call build_installer.bat


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
