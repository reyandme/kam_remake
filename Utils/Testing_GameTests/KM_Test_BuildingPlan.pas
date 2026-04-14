unit KM_Test_BuildingPlan;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMRunnerBuilding_Plan = class(TKMTest)
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
  KM_ResMapElements,
  KM_GameParams,
  KM_Exceptions,
  KM_CampaignTypes,
  KM_HandSpectator, KM_ResHouses, KM_Hand, KM_HandTypes, KM_UnitsCollection, KM_UnitGroup,
  KM_GameSettings,
  KM_CommonTypes, KM_MapTypes, KM_FileIO, KM_Game, KM_GameInputProcess, KM_GameTypes, KM_InterfaceGame,
  KM_UnitGroupTypes,
  KM_ResTypes, KM_CampaignClasses;

procedure TKMRunnerBuilding_Plan.SetUp;
begin
  inherited;
  fResults.ValueCount := 1;
  gGameApp.NewEmptyMap(32, 32);

  // Add the house plan for the school at (16, 20)
  gHands[0].AddHousePlan(htSchool, KMPoint(16, 20));
  
  // Add the builder unit nearby
  gHands[0].AddUnit(utBuilder, KMPoint(16, 21));

  // Initialize passability so builder can evaluate CanWalkTo
  gHands[0].AfterMissionInit(False);
  gTerrain.UpdatePassability;
end;

function TKMRunnerBuilding_Plan.OnTickCondition(aTick: Cardinal): Boolean;
var
  I: Integer;
  H: TKMHouse;
begin
  // Continue simulation (True) until the house plan is fully dug out
  Result := True;
  for I := 0 to gHands[0].Houses.Count - 1 do
  begin
    H := gHands[0].Houses[I];
    if (H.HouseType = htSchool) and (H.BuildingState >= hbsWood) then
      Result := False; // Dug out
  end;
end;

procedure TKMRunnerBuilding_Plan.Execute(aRun: Integer);
var
  I: Integer;
  H: TKMHouse;
begin
  SetKaMSeed(aRun+1);
  SimulateGame;

  fResults.Value[aRun, 0] := 0;
  
  // If the house reached hbsWood state, the builder has finished clearing the site
  for I := 0 to gHands[0].Houses.Count - 1 do
  begin
    H := gHands[0].Houses[I];
    if (H.HouseType = htSchool) and (H.BuildingState >= hbsWood) then
      fResults.Value[aRun, 0] := 1;
  end;

  AssertTrue(fResults.Value[aRun, 0] = 1, 'Builder should have dug out the house plan');

  gGameApp.StopGame(grSilent);
end;

class function TKMRunnerBuilding_Plan.TestCategories: TKMTestCategorySet;
begin
  Result := [tcBuilder, tcSchool];
end;

class function TKMRunnerBuilding_Plan.TestDescription: string;
begin
  Result := 'Tests a builder''s ability to dig out a house plan.';
end;

initialization
  RegisterRunner(TKMRunnerBuilding_Plan);
end.
