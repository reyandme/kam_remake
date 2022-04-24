@echo off
if not exist rsvars_local.bat (goto exit2)

if defined RS_INIT (
if %RS_INIT%==True (
goto exit0
)
)

@SET RS_INIT=True

call rsvars_local.bat

@SET BDS=%BDS_LOCAL%
@SET BDSCOMMONDIR=%BDSCOMMONDIR_LOCAL%
@SET ISC_DIR=%ISC_DIR_LOCAL%
@SET MADEXCEPT_TOOLS=%MADEXCEPT_TOOLS_LOCAL%
@SET LAZARUS_LINUX=%LAZARUS_LINUX_LOCAL%
@SET FrameworkDir=%FrameworkDir_LOCAL%
@SET FrameworkVersion=%FrameworkVersion_LOCAL%
@SET FrameworkSDKDir=%FrameworkSDKDir_LOCAL%
@SET KMRMapsRepoDir=%KMRMapsRepoDir_LOCAL%
@SET KMRPrivateRepoDir=%KMRPrivateRepoDir_LOCAL%
@SET KMRResourcesRepoDir=%KMRResourcesRepoDir_LOCAL%
@SET KaMOrigDir=%KaMOrigDir_LOCAL%
@SET KMRPrevVersionDir=%KMRPrevVersionDir_LOCAL%
@SET SpritesRXADir=%SpritesRXADir_LOCAL%
@SET BuildFullDir=%BuildFullDir_LOCAL%
@SET KMRVideosDir=%KMRVideosDir_LOCAL%
@SET ScriptingEditorDir=%ScriptingEditorDir_LOCAL%
@SET PATH=%FrameworkDir%;%FrameworkSDKDir%;%BDS%\bin;%BDS%\bin64;%MADEXCEPT_TOOLS%;%PATH%
@SET kam_version=Beta

@SET IncludeScriptingEditor=True

goto exit0

:exit2
@echo !
@echo !
@echo ================================================================================
@echo ###########          FILE `RSVARS_LOCAL.BAT` NOT FOUND !!!!!         ###########
@echo ================================================================================
@echo !  
@echo !
@echo off
exit /B 2

:exit0
@echo off
exit /B 0