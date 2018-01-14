
call bat_get_kam_folder.bat

echo ***************
echo "%build_full_kmr_dir%"

@SET KMR_EXEs_ARCH=%build_full_kmr_dir%_exes
@SET KMR_EXEs_ARCH_7Z=%KMR_EXEs_ARCH%.7z

@REM Recreate special KMR_EXEs_ARCH folder
rmdir /S /Q "%KMR_EXEs_ARCH%"
mkdir "%KMR_EXEs_ARCH%"

@REM rename and copy all exe's into KMR_EXEs_ARCH folder
rem @echo off
for /R "%build_full_kmr_dir%" %%G in (*.exe) do (
	xcopy "%build_full_kmr_dir%"\"%%~nG.exe" "%KMR_EXEs_ARCH%\%%~nG_r%kam_revision%.exe*" /y /r /s
) 

REM ============================================================
REM Erase previous archive to make sure new one is made from scratch
REM ============================================================
erase /F /Q /S "%KMR_EXEs_ARCH_7Z%"

REM ============================================================
REM Create archive with all exe's
REM ============================================================
"C:\Program Files\7-Zip\7z.exe" a "%KMR_EXEs_ARCH_7Z%" "%KMR_EXEs_ARCH%"/*.exe

rmdir /S /Q "%KMR_EXEs_ARCH%"
