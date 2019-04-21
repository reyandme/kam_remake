call rsvars.bat

@REM Build utils applications, included into the final build

REM Build Campaign Builder
msbuild "..\Utils\Campaign builder\CampaignBuilder.dproj" /p:Configuration=Release /t:Build /clp:ErrorsOnly /fl /flp:LogFile="build_campaign_builder.log"

REM Build Dedicated Server (Console app)
msbuild ..\Utils\DedicatedServer\KaM_DedicatedServer.dproj /p:Configuration=Release /t:Build /clp:ErrorsOnly /fl /flp:LogFile="build_dedicated_server.log"

REM Build Dedicated Server (GUI app)
msbuild ..\Utils\DedicatedServerGUI\KaM_DedicatedServerGUI.dproj /p:Configuration=Release /t:Build /clp:ErrorsOnly /fl /flp:LogFile="build_dedicated_server_gui.log"

REM Build Script Validator
msbuild ..\Utils\ScriptValidator\ScriptValidator.dproj /p:Configuration=Release /t:Build /clp:ErrorsOnly /fl /flp:LogFile="build_script_validator.log"

REM Build Translation Manager
msbuild ..\Utils\TranslationManager\TranslationManager.dproj /p:Configuration=Release /t:Build /clp:ErrorsOnly /fl /flp:LogFile="build_translation_manager.log"

REM Build Scripting Editor
if %IncludeScriptingEditor%==True (
msbuild "%ScriptingEditorDir%"\ScriptingEditor.dproj /p:Configuration=Release /t:Build /clp:ErrorsOnly /fl /flp:LogFile="build_script_editor.log"
)

call build_linux_servers.bat
