unit KM_Test_Woodcutter_Plant;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMTest_WoodcutterPlant = class(TKMTest)
  protected
    procedure DoTick(aTick: Cardinal; var aKeepGoing: Boolean); override;
    procedure SetUp; override;
    procedure CheckResult; override;
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

  gGameApp.NewGameEmptyMap(32, 32);

  TKMHouseWoodcutters(gHands[0].AddHouse(htWoodcutters, 16, 20, False)).WoodcutterMode := wmPlant;

  gHands[0].AddUnit(utWoodcutter, KMPoint(16, 17));
end;


procedure TKMTest_WoodcutterPlant.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  // Continue simulation (True) until at least one tree (caAge1) is planted near the house
  for var Y := 10 to 25 do
    for var X := 10 to 25 do
      if gTerrain.ObjectIsChopableTree(KMPoint(X, Y), [caAge1]) then
      begin
        aKeepGoing := False;
        Exit;
      end;
end;


procedure TKMTest_WoodcutterPlant.CheckResult;
begin
  var plantedTreeCount := 0;
  for var Y := 10 to 25 do
    for var X := 10 to 25 do
      if gTerrain.ObjectIsChopableTree(KMPoint(X, Y), [caAge1]) then
        Inc(plantedTreeCount);

  AssertTrue(plantedTreeCount > 0, 'Woodcutter should have planted at least one tree');
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
