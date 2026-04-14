unit KM_Test_Woodcutter_Plant;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMTest_WoodcutterPlant = class(TKMTest)
  protected
    function DoTick(aTick: Cardinal): Boolean; override;
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;

implementation
uses
  KM_Defaults, KM_Points, KM_CommonUtils,
  KM_GameApp, KM_HandsCollection, KM_Terrain, KM_HouseWoodcutters,
  KM_ResMapElements, KM_ResTypes;


{ TKMTest_WoodcutterPlant }
procedure TKMTest_WoodcutterPlant.SetUp;
begin
  inherited;
  fResults.ValueCount := 1;

  gGameApp.NewEmptyMap(32, 32);

  TKMHouseWoodcutters(gHands[0].AddHouse(htWoodcutters, 16, 20, False)).WoodcutterMode := wmPlant;

  gHands[0].AddUnit(utWoodcutter, KMPoint(16, 17));
end;


function TKMTest_WoodcutterPlant.DoTick(aTick: Cardinal): Boolean;
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


procedure TKMTest_WoodcutterPlant.Execute(aRun: Integer);
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


class function TKMTest_WoodcutterPlant.TestTags: TKMTestTagSet;
begin
  Result := [tcWoodcutters, tcWoodcutter, tcPlantTree];
end;


class function TKMTest_WoodcutterPlant.TestDescription: string;
begin
  Result := 'Tests a woodcutter''s ability to plant a sapling.';
end;


initialization
  RegisterTest(TKMTest_WoodcutterPlant);
end.
