unit KM_Test_Woodcutter_Chop;
{$I KaM_Remake.inc}
interface
uses
  Unit_Runner;

type
  TKMRunnerWoodcutter_Chop = class(TKMRunnerCommon)
  protected
    function OnTickCondition(aTick: Cardinal): Boolean; override;
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
    procedure TearDown; override;
  public
    class function TestCategories: TKMTestCategorySet; override;
    class function TestDescription: UnicodeString; override;
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
  KM_ResTypes, KM_CampaignClasses, KM_ResMapElements;

{ TKMRunnerWoodcutter_Chop }
procedure TKMRunnerWoodcutter_Chop.SetUp;
var
  treeObjID: Integer;
  TargetLoc: TKMPoint;
begin
  inherited;
  fResults.ValueCount := 1;

  gGameApp.NewEmptyMap(32, 32);

  TargetLoc := KMPoint(16, 23);

  // Set a full-grown tree for chopping
  treeObjID := gTerrain.ChooseTreeToPlace(TargetLoc, caAgeFull, True);
  gTerrain.SetObject(TargetLoc, treeObjID);
  
  // Set TreeAge so the tree is immediately chop-able, skipping the 10 min growth wait
  gTerrain.Land[TargetLoc.Y, TargetLoc.X].TreeAge := TREE_AGE_FULL;

  // Set the woodcutter's house
  TKMHouseWoodcutters(gHands[0].AddHouse(htWoodcutters, 16, 20, False)).WoodcutterMode := wmChop;
  
  // Add the woodcutter unit just outside the house
  gHands[0].AddUnit(utWoodcutter, KMPoint(16, 21));
end;


procedure TKMRunnerWoodcutter_Chop.TearDown;
begin
  inherited;
end;

function TKMRunnerWoodcutter_Chop.OnTickCondition(aTick: Cardinal): Boolean;
begin
  // Continue simulation (True) until a trunk is produced
  Result := gHands[0].Stats.GetWaresProduced(wtTrunk) = 0;
end;

procedure TKMRunnerWoodcutter_Chop.Execute(aRun: Integer);
begin
  SetKaMSeed(aRun+1);
  
  // Run the simulation loop
  SimulateGame;

  // The woodcutter should have found the tree, chopped it, and delivered the trunk.
  fResults.Value[aRun, 0] := gHands[0].Stats.GetWaresProduced(wtTrunk);

  AssertTrue(fResults.Value[aRun, 0] > 0, 'Woodcutter should have chopped and delivered a trunk');

  gGameApp.StopGame(grSilent);
end;

class function TKMRunnerWoodcutter_Chop.TestCategories: TKMTestCategorySet;
begin
  Result := [tcWoodcutters, tcWoodcutter, tcChopTree];
end;

class function TKMRunnerWoodcutter_Chop.TestDescription: UnicodeString;
begin
  Result := 'Tests a woodcutter''s ability to find a tree, chop it, and bring a log to the house.';
end;

initialization
  RegisterRunner(TKMRunnerWoodcutter_Chop);
end.
