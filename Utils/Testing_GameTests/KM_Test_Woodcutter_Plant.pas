unit KM_Test_Woodcutter_Plant;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMRunnerWoodcutter_Plant = class(TKMTest)
  protected
    function OnTickCondition(aTick: Cardinal): Boolean; override;
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
    procedure TearDown; override;
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
  KM_HouseWoodcutters,
  KM_GameParams,
  KM_Exceptions,
  KM_CampaignTypes,
  KM_HandSpectator, KM_ResHouses, KM_Hand, KM_HandTypes, KM_UnitsCollection, KM_UnitGroup,
  KM_GameSettings,
  KM_CommonTypes, KM_MapTypes, KM_FileIO, KM_Game, KM_GameInputProcess, KM_GameTypes, KM_InterfaceGame,
  KM_UnitGroupTypes,
  KM_ResTypes, KM_CampaignClasses;

{ TKMRunnerWoodcutter_Plant }
procedure TKMRunnerWoodcutter_Plant.SetUp;
begin
  inherited;
  fResults.ValueCount := 1;

  gGameApp.NewEmptyMap(32, 32);

  // Set the woodcutter's house and force plant mode
  TKMHouseWoodcutters(gHands[0].AddHouse(htWoodcutters, 16, 20, False)).WoodcutterMode := wmPlant;
  
  // Add the woodcutter unit just outside the house
  gHands[0].AddUnit(utWoodcutter, KMPoint(16, 17));
end;


procedure TKMRunnerWoodcutter_Plant.TearDown;
begin
  inherited;
end;

function TKMRunnerWoodcutter_Plant.OnTickCondition(aTick: Cardinal): Boolean;
var
  X, Y: Integer;
begin
  // Continue simulation (True) until at least one tree (caAge1) is planted near the house
  Result := True;
  
  for Y := 10 to 25 do
    for X := 10 to 25 do
      if gTerrain.ObjectIsChopableTree(KMPoint(X, Y), [caAge1]) then
        Exit(False);
end;

procedure TKMRunnerWoodcutter_Plant.Execute(aRun: Integer);
var
  X, Y: Integer;
  PlantedTreeCount: Integer;
begin
  SetKaMSeed(aRun+1);
  
  SimulateGame;

  PlantedTreeCount := 0;
  for Y := 10 to 25 do
    for X := 10 to 25 do
      if gTerrain.ObjectIsChopableTree(KMPoint(X, Y), [caAge1]) then
        Inc(PlantedTreeCount);

  fResults.Value[aRun, 0] := PlantedTreeCount;

  AssertTrue(fResults.Value[aRun, 0] > 0, 'Woodcutter should have planted at least one tree');

  gGameApp.StopGame(grSilent);
end;

class function TKMRunnerWoodcutter_Plant.TestCategories: TKMTestCategorySet;
begin
  Result := [tcWoodcutters, tcWoodcutter, tcPlantTree];
end;

class function TKMRunnerWoodcutter_Plant.TestDescription: string;
begin
  Result := 'Tests a woodcutter''s ability to plant a sapling.';
end;

initialization
  RegisterTest(TKMRunnerWoodcutter_Plant);
end.
