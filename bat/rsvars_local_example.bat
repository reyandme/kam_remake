@REM Variable which ensures this script (rsvars_local.bat) was called
@SET LOCAL_VARS_SCRIPT_LOADED=True

@REM Path to your Delphi or RAD studio installation
@SET BDS_LOCAL=C:\Program Files (x86)\Embarcadero\Studio\21.0

@REM Path to your Delphi or RAD studio common dir
@SET BDSCOMMONDIR_LOCAL=C:\Users\Public\Documents\Embarcadero\Studio\21.0

@REM Path to madexcept unit
@SET MADEXCEPT_TOOLS_LOCAL=C:\Program Files (x86)\madCollection\madExcept\Tools

@REM Path to Inno Setup installation
@SET ISC_DIR_LOCAL=C:\Program Files (x86)\Inno Setup 6

@REM Path to Lazarus cross-platform installation for Linux
@SET LAZARUS_LINUX_LOCAL=C:\fpcupdeluxe\fpcdeluxe_3.0.0_1.8.0\lazarus

@REM Path to Microsoft .NET Framework 
@SET FrameworkDir_LOCAL=C:\Windows\Microsoft.NET\Framework\v4.0.30319

@REM Microsoft .NET Framework version
@SET FrameworkVersion_LOCAL=v4.0

@REM Microsoft .NET Framework version SDK Dir (not used atm)
@SET FrameworkSDKDir_LOCAL=

@REM Path to cloned kam_remake_maps repository
@SET KMRMapsRepoDir_LOCAL=F:\Development_Win7\Repos\kam_remake_maps

@REM Path to cloned kam_remake_private repository, if existing
@SET KMRPrivateRepoDir_LOCAL=F:\Development_Win7\Repos\kam_remake_private

@REM Path to cloned ScriptingEditor repository
@SET ScriptingEditorDir_LOCAL=F:\Development_Win7\Repos\ScriptingEditor

@REM Path to cloned kam_remake_resources repository
@SET KMRResourcesRepoDir_LOCAL=F:\Development_Win7\Repos\kam_remake_resources

@REM Path to Knights and Merchants The Peasants Rebellion
@SET KaMOrigDir_LOCAL=F:\Games\KaM The Peasants Rebellion

@REM Path to KMR older version, f.e. r6720 or other Beta version
@SET KMRPrevVersionDir_LOCAL=F:\games\KaM Remake

@REM RXA sprites dir. Previous Beta version could be used
@SET SpritesRXADir_LOCAL=D:\Games\KaM Remake Beta r15122\data\Sprites

@REM Path to the folder, where new build will be made
@SET BuildFullDir_LOCAL=F:\KaM_Remake Beta

@REM Path to Pandoc folder, for documentation generation
@SET PandocDir_LOCAL=F:\Development_Win7\pandoc-3.6.4
