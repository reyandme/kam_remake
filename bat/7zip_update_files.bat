
call get_kam_folder.bat

echo ***************
echo "%build_full_kmr_dir%"

@SET KMR_UPDATE_ARCH=%build_full_kmr_dir%_update
@SET KMR_UPDATE_ARCH_7Z=%KMR_UPDATE_ARCH%.7z

@REM Recreate special KMR_UPDATE_ARCH folder
rmdir /S /Q "%KMR_UPDATE_ARCH%"
mkdir "%KMR_UPDATE_ARCH%"

@REM rename and copy all exe's  into KMR_UPDATE_ARCH folder
rem @echo off
for /R "%build_full_kmr_dir%" %%G in (*.exe) do (
  xcopy "%build_full_kmr_dir%"\"%%~nG.exe" "%KMR_UPDATE_ARCH%\%%~nG_r%kam_revision%.exe*" /y /r /s
)

@REM copy linux dedicated servers
copy /y "%build_full_kmr_dir%"\KaM_Remake_Server_linux_x86 "%KMR_UPDATE_ARCH%\KaM_Remake_Server_linux_x86_r%kam_revision%"
copy /y "%build_full_kmr_dir%"\KaM_Remake_Server_linux_x86_64 "%KMR_UPDATE_ARCH%\KaM_Remake_Server_linux_x86_64_r%kam_revision%"

REM ============================================================
REM Erase previous archive to make sure new one is made from scratch
REM ============================================================
erase /F /Q /S "%KMR_UPDATE_ARCH_7Z%"

REM ============================================================
REM Create archive with all exe's
REM ============================================================
"C:\Program Files\7-Zip\7z.exe" a "%KMR_UPDATE_ARCH_7Z%" "%KMR_UPDATE_ARCH%"

rmdir /S /Q "%KMR_UPDATE_ARCH%"
