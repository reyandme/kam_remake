@echo off
echo called build_exe.bat

@REM Unset vars we use to determine multiple includes
@REM @SET RS_INIT=False
@REM @SET KAM_FOLDER_INIT=False

@REM ============================================================
@REM Build main exe
@REM ============================================================

@REM msbuild needs variables set by rsvars
call rsvars.bat

REM build
msbuild ..\KaM_Remake.dproj /p:config=Release /target:Build /p:platform=Win32 /clp:ErrorsOnly /fl /flp:LogFile="build_exe.log"

REM ============================================================
REM Patch main exe with madExcept
REM ============================================================

call madExceptPatch.exe ..\KaM_Remake.exe
