REM ============================================================
REM Create new version package
REM ============================================================

REM Clean before build to avoid any side-effects from old DCUs
call get_kam_folder.bat

echo "%kam_folder%"

REM Clean target, so if anything fails we have a clear indication (dont pack old files by mistake)
rmdir /S /Q "%kam_folder%"

REM Clean before build to avoid any side-effects from old DCUs
@call clean_src.bat

REM Copy_1
call copy_pre_pack.bat

REM Pack rx data
call rx_pack.bat

REM Build utility applications, included into the final build
call build_utils.bat

@REM Build exe
@REM call build_exe.bat

@REM Patch exe
@REM call patch_exe.bat

REM Copy_2
call copy_post_pack.bat

@REM Restore local rxx
@REM call rxx_restore.bat

@REM Archive into 7z
@REM call 7zip.bat

@REM Create Installer instructions
@REM call prepare_installer.bat

@REM Build Installer
@REM call build_installer.bat
