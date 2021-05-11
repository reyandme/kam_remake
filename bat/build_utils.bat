echo called build_utils.bat

call rsvars.bat

@REM Build utils applications, included into the final build

REM Build Campaign Builder
msbuild "..\Utils\Campaign builder\CampaignBuilder.dproj" /p:Configuration=Release /t:Build /clp:ErrorsOnly /fl /flp:LogFile="build_campaign_builder.log"
if errorlevel 1 goto exit3

REM Build Dedicated Server (Console app)
msbuild ..\Utils\DedicatedServer\KaM_DedicatedServer.dproj /p:Configuration=Release /t:Build /clp:ErrorsOnly /fl /flp:LogFile="build_dedicated_server.log"
if errorlevel 1 goto exit3

REM Build Dedicated Server (GUI app)
msbuild ..\Utils\DedicatedServerGUI\KaM_DedicatedServerGUI.dproj /p:Configuration=Release /t:Build /clp:ErrorsOnly /fl /flp:LogFile="build_dedicated_server_gui.log"
if errorlevel 1 goto exit3

REM Build Script Validator
msbuild ..\Utils\ScriptValidator\ScriptValidator.dproj /p:Configuration=Release /t:Build /clp:ErrorsOnly /fl /flp:LogFile="build_script_validator.log"
if errorlevel 1 goto exit3

REM Build Translation Manager
msbuild ..\Utils\TranslationManager\TranslationManager.dproj /p:Configuration=Release /t:Build /clp:ErrorsOnly /fl /flp:LogFile="build_translation_manager.log"
if errorlevel 1 goto exit3

REM Build Scripting Editor
if %IncludeScriptingEditor%==True (
  msbuild "%ScriptingEditorDir%"\ScriptingEditor.dproj /p:Configuration=Release /t:Build /clp:ErrorsOnly /fl /flp:LogFile="build_script_editor.log"
  if errorlevel 1 goto exit3
)

call build_linux_servers.bat
if errorlevel 1 goto exit3

goto exit0

:exit3
@echo off
exit /B 3

:exit0
@echo off
exit /B 0

