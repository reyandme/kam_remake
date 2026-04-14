unit KM_Test_Bakery;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMRunnerBakery_Process = class(TKMTest)
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

procedure TKMRunnerBakery_Process.SetUp;
var
  H: TKMHouse;
  I: Integer;
begin
  inherited;
  fResults.ValueCount := 1;
  gGameApp.NewEmptyMap(32, 32);

  // Add the bakery
  H := gHands[0].AddHouse(htBakery, 16, 16, False);

  H.ResIn[1] := 1;

  // Add the baker unit
  gHands[0].AddUnit(utBaker, KMPoint(16, 17));
end;

function TKMRunnerBakery_Process.OnTickCondition(aTick: Cardinal): Boolean;
begin
  // Keep running until bread is produced
  Result := gHands[0].Stats.GetWaresProduced(wtBread) = 0;
end;

procedure TKMRunnerBakery_Process.Execute(aRun: Integer);
begin
  SetKaMSeed(aRun+1);
  SimulateGame;

  // Check if it produced something
  fResults.Value[aRun, 0] := gHands[0].Stats.GetWaresProduced(wtBread);

  AssertTrue(fResults.Value[aRun, 0] >= 1, 'Bakery should have processed flour and water into bread');

  gGameApp.StopGame(grSilent);
end;

class function TKMRunnerBakery_Process.TestCategories: TKMTestCategorySet;
begin
  Result := [tcBakery, tcBaker, tcEconomy];
end;

class function TKMRunnerBakery_Process.TestDescription: string;
begin
  Result := 'Tests the bakery''s ability to process flour and water from the internal stock into bread.';
end;

initialization
  RegisterTest(TKMRunnerBakery_Process);
end.
