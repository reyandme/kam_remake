@echo off
echo called prepare_for_installer.bat

call rsvars.bat
call get_kam_folder.bat

@REM @SET kam_folder=%installer_kmr_build_full_dir%

@SET CONST_LOCAL_FILENAME=Constants_local

@REM del '..\Installer\%CONST_LOCAL_FILENAME%.iss' 
erase /F /Q /S "..\Installer\%CONST_LOCAL_FILENAME%.iss"

@echo #define BuildFolder "%kam_folder%" > "..\Installer\%CONST_LOCAL_FILENAME%.iss"
@echo #define OutputFolder "%BuildFullDir%" >> "..\Installer\%CONST_LOCAL_FILENAME%.iss"
@REM @echo #define MyAppFullName "KaM Remake Beta r%kam_revision%" >> "..\Installer\%CONST_LOCAL_FILENAME%.iss"

@REM call create.bat
