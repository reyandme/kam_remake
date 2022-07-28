program uniteditor;
{$I uniteditor.inc}
{$IFDEF FPC}
  {$Mode Delphi} {$H+}
{$ENDIF}

uses
  {$IFDEF UNIX}
    {$IFDEF UseCThreads}
      cthreads,
    {$ENDIF}
  {$ENDIF}
  {$IFDEF FPC}
    Interfaces,
  {$ENDIF}
  Forms,
  ueMainForm in 'ueMainForm.pas' {MainForm},

  { KMR units }
  KM_ResUnits in '../../src/res/KM_ResUnits.pas',

  { dependencies... }
  KM_CommonClasses in '../../src/common/KM_CommonClasses.pas',
  KM_CommonTypes in '../../src/common/KM_CommonTypes.pas',
  KM_Defaults in '../../src/common/KM_Defaults.pas',
  KM_Points in '../../src/common/KM_Points.pas',
  KM_WorkerThread in '../../src/common/KM_WorkerThread.pas',

  KM_CommonUtils in '../../src/utils/KM_CommonUtils.pas',
  KromUtils in '../../src/utils/KromUtils.pas',
  KM_IoXML in '../../src/utils/io/KM_IoXML.pas',
  KM_FileIO in '../../src/utils/io/KM_FileIO.pas',

  KM_GameParams in '../../src/game/KM_GameParams.pas',
  KM_GameTypes in '../../src/game/KM_GameTypes.pas',
  KM_RandomChecks in '../../src/game/misc/KM_RandomChecks.pas',

  KM_ResTilesetTypes in '../../src/res/KM_ResTilesetTypes.pas',
  KM_ResWares in '../../src/res/KM_ResWares.pas',
  KM_ResTypes in '../../src/res/KM_ResTypes.pas',
  KM_ResHouses in '../../src/res/KM_ResHouses.pas',
  KM_ResTexts in '../../src/res/KM_ResTexts.pas',
  KM_ResLocales in '../../src/res/KM_ResLocales.pas',

  KM_WareDistribution in '../../src/hands/KM_WareDistribution.pas',

  KM_CampaignTypes in '../../src/mission/KM_CampaignTypes.pas',
  KM_MapTypes in '../../src/mission/KM_MapTypes.pas',
  KM_MapUtils in '../../src/mission/KM_MapUtils.pas',

  KM_InterfaceTypes in '../../src/gui/KM_InterfaceTypes.pas',

  KM_GameSettings in '../../src/settings/KM_GameSettings.pas',
  KM_GameAppSettingsPart in '../../src/settings/KM_GameAppSettingsPart.pas',

  KM_TerrainTypes in '../../src/terrain/KM_TerrainTypes.pas',

  KM_Outline in '../../src/navmesh/KM_Outline.pas',
  KM_PolySimplify in '../../src/navmesh/KM_PolySimplify.pas';

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

