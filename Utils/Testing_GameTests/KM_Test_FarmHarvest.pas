unit KM_Test_FarmHarvest;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMRunnerFarm_Harvest = class(TKMTest)
  protected
    function DoTick(aTick: Cardinal): Boolean; override;
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

procedure TKMRunnerFarm_Harvest.SetUp;
begin
  inherited;
  fResults.ValueCount := 1;
  gGameApp.NewEmptyMap(32, 32);

  gHands[0].AddHouse(htFarm, 16, 20, False);

  // Field plan at (16, 12) -> Stage 5 is ready to harvest
  gHands[0].AddField(KMPoint(16, 22), ftCorn, 5, False, True);
  
  // Add the farmer unit
  gHands[0].AddUnit(utFarmer, KMPoint(16, 21));
end;

function TKMRunnerFarm_Harvest.DoTick(aTick: Cardinal): Boolean;
var
  H: TKMHouse;
begin
  Result := True;
  H := gHands[0].FindHouse(htFarm);
  if H <> nil then
  begin
    if H.ResOut[1] > 0 then
      Result := False;
  end;
end;

procedure TKMRunnerFarm_Harvest.Execute(aRun: Integer);
var
  H: TKMHouse;
begin
  SetKaMSeed(aRun+1);
  SimulateGame;

  fResults.Value[aRun, 0] := 0;
  H := gHands[0].FindHouse(htFarm);
  if H <> nil then
  begin
    fResults.Value[aRun, 0] := H.ResOut[1];
  end;

  AssertTrue(fResults.Value[aRun, 0] > 0, 'Farmer should have harvested corn and delivered it to farm');

  gGameApp.StopGame(grSilent);
end;

class function TKMRunnerFarm_Harvest.TestCategories: TKMTestCategorySet;
begin
  Result := [tcFarm, tcChopTree];
end;

class function TKMRunnerFarm_Harvest.TestDescription: string;
begin
  Result := 'Tests a farmer''s ability to collect ripe wheat and carry it back to the farm.';
end;

initialization
  RegisterTest(TKMRunnerFarm_Harvest);
end.
