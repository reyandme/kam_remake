@REM
echo called 7z_utils.bat

call get_kam_folder.bat

@SET kmr_utils=KMR_Utils_r%kam_revision%

@echo off

REM ===============================================================
REM Erase previous archive to make sure new one is made from scratch
REM ===============================================================
erase /F /Q /S "%BuildFullDir%\%kmr_utils%.7z"



REM ============================================================
REM Create archive
REM ============================================================
"C:\Program Files\7-Zip\7z.exe" a -mx=9 "%BuildFullDir%\%kmr_utils%.7z" "%kam_folder%\Utils"
