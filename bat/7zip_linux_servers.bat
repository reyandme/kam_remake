@REM
echo called 7z_linux_servers.bat

call get_kam_folder.bat

@SET kmr_linux_servers=KMR_linux_dedicated_servers_r%kam_revision%_net_v%kmr_net_protocol%

@echo off

REM ===============================================================
REM Erase previous archive to make sure new one is made from scratch
REM ===============================================================
erase /F /Q /S "%BuildFullDir%\%kmr_linux_servers%.7z"



REM ============================================================
REM Create archive
REM ============================================================
"C:\Program Files\7-Zip\7z.exe" a -mx=9 "%BuildFullDir%\%kmr_linux_servers%.7z" "%kam_folder%\Utils\KaM_Remake_Server_linux_x86" "%kam_folder%\Utils\KaM_Remake_Server_linux_x86_64"
