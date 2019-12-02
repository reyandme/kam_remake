REM ============================================================
REM Build DedicatedServer for Linux
REM ============================================================

REM msbuild needs variables set by rsvars
call rsvars.bat

REM Build x86 version 
call %LAZARUS_LINUX%/lazbuild.exe -q ../Utils/DedicatedServer/KaM_DedicatedServer_win32-linux_x86.lpi
  
REM Build x86_64 (x64) version 
call %LAZARUS_LINUX%/lazbuild.exe -q ../Utils/DedicatedServer/KaM_DedicatedServer_win32-linux_x86_64.lpi
 