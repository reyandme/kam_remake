REM ============================================================
REM Create new version package
REM ============================================================

REM Clean before build to avoid any side-effects from old DCUs
call bat_get_kam_folder.bat

echo "%kam_folder%"

REM Clean target, so if anything fails we have a clear indication (dont pack old files by mistake)
rmdir /S /Q "%kam_folder%"

REM Clean before build to avoid any side-effects from old DCUs
@call bat_clean_src.bat

REM Copy_1
call bat_copy_pre_pack.bat

REM Pack rx data
call bat_rx_pack.bat

REM Build utility applications, included into the final build
call bat_build_utils.bat

@REM Build exe
@REM call bat_build_exe.bat

@REM Patch exe
@REM call bat_patch_exe.bat

REM Copy_2
call bat_copy_post_pack.bat

@REM Restore local rxx
@REM call bat_rxx_restore.bat

@REM Archive into 7z
@REM call bat_7zip.bat

@REM Create Installer instructions
@REM call bat_prepare_installer.bat

@REM Build Installer
@REM call bat_build_installer.bat
