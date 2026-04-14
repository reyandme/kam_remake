unit KM_Test_Sawmill;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMRunnerSawmill_Process = class(TKMTest)
  protected
    function OnTickCondition(aTick: Cardinal): Boolean; override;
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
  public
    class function TestCategories: TKMTestCategorySet; override;
    class function TestDescription: string; override;
  end;

implementation
uses
  Windows, SysUtils, Classes, Math,
  Generics.Collections, Generics.Defaults,
  KM_CommonClasses, KM_Defaults, KM_Points, KM_CommonUtils,
  KM_GameApp, KM_Log, KM_HandsCollection, KM_HouseCollection, KM_Resource,
  KM_Terrain, KM_Units, KM_Campaigns, KM_Houses,
  KM_GameParams,
  KM_Exceptions,
  KM_CampaignTypes,
  KM_HandSpectator, KM_ResHouses, KM_Hand, KM_HandTypes, KM_UnitsCollection, KM_UnitGroup,
  KM_GameSettings,
  KM_CommonTypes, KM_MapTypes, KM_FileIO, KM_Game, KM_GameInputProcess, KM_GameTypes, KM_InterfaceGame,
  KM_UnitGroupTypes,
  KM_ResTypes, KM_CampaignClasses;

procedure TKMRunnerSawmill_Process.SetUp;
var
  H: TKMHouse;
begin
  inherited;
  fResults.ValueCount := 1;
  gGameApp.NewEmptyMap(32, 32);

  // Add the sawmill
  H := gHands[0].AddHouse(htSawmill, 16, 16, False);

  // Input 1 for Sawmill is wtTrunk
  H.ResIn[1] := 1;

  // Add the carpenter unit
  gHands[0].AddUnit(utCarpenter, KMPoint(16, 17));
end;

function TKMRunnerSawmill_Process.OnTickCondition(aTick: Cardinal): Boolean;
begin
  // Keep running until wood is produced
  Result := gHands[0].Stats.GetWaresProduced(wtTimber) = 0;
end;

procedure TKMRunnerSawmill_Process.Execute(aRun: Integer);
begin
  SetKaMSeed(aRun+1);
  SimulateGame;

  // Check if it produced something
  fResults.Value[aRun, 0] := gHands[0].Stats.GetWaresProduced(wtTimber);

  AssertTrue(fResults.Value[aRun, 0] >= 2, 'Sawmill should have processed trunk into 2 timber');

  gGameApp.StopGame(grSilent);
end;

class function TKMRunnerSawmill_Process.TestCategories: TKMTestCategorySet;
begin
  Result := [tcSawmill, tcEconomy];
end;

class function TKMRunnerSawmill_Process.TestDescription: string;
begin
  Result := 'Tests the sawmill (carpenter''s) ability to process one trunk from the internal stock into two boards.';
end;

initialization
  RegisterTest(TKMRunnerSawmill_Process);
end.
