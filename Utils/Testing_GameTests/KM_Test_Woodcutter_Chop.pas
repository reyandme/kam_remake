unit KM_Test_Woodcutter_Chop;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMTest_WoodcutterChop = class(TKMTest)
  protected
    function DoTick(aTick: Cardinal): Boolean; override;
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


{ TKMTest_WoodcutterChop }
procedure TKMTest_WoodcutterChop.SetUp;
var
  treeObjID: Integer;
  TargetLoc: TKMPoint;
begin
  inherited;

  gGameApp.NewEmptyMap(32, 32);

  TargetLoc := KMPoint(16, 23);

  // Set a full-grown tree for chopping
  treeObjID := gTerrain.ChooseTreeToPlace(TargetLoc, caAgeFull, True);
  gTerrain.SetObject(TargetLoc, treeObjID);

  // Set TreeAge so the tree is immediately chop-able, skipping the 10 min growth wait
  gTerrain.Land[TargetLoc.Y, TargetLoc.X].TreeAge := TREE_AGE_FULL;

  TKMHouseWoodcutters(gHands[0].AddHouse(htWoodcutters, 16, 20, False)).WoodcutterMode := wmChop;

  gHands[0].AddUnit(utWoodcutter, KMPoint(16, 21));
end;


function TKMTest_WoodcutterChop.DoTick(aTick: Cardinal): Boolean;
begin
  // Continue simulation (True) until a trunk is produced
  Result := gHands[0].Stats.GetWaresProduced(wtTrunk) = 0;
end;


procedure TKMTest_WoodcutterChop.CheckResult;
begin
  AssertTrue(gHands[0].Stats.GetWaresProduced(wtTrunk) > 0, 'Woodcutter should have chopped and delivered a trunk');
end;


class function TKMTest_WoodcutterChop.TestTags: TKMTestTagSet;
begin
  Result := [tcWoodcutters, tcWoodcutter, tcChopTree];
end;


class function TKMTest_WoodcutterChop.TestDescription: string;
begin
  Result := 'Tests a woodcutter''s ability to find a tree, chop it, and bring a log to the house.';
end;


initialization
  RegisterTest(TKMTest_WoodcutterChop);
end.
