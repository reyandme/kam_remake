@REM
call get_kam_folder.bat

REM ============================================================
REM Erase previous archive to make sure new one is made from scratch
REM ============================================================
erase /F /Q /S "%kam_folder%.7z"

REM ============================================================
REM Create archive
REM ============================================================
"C:\Program Files\7-Zip\7z.exe" a "%kam_folder%.7z" "%kam_folder%"
