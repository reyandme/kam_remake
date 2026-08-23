unit KM_Test_Hungarian_LongWalk;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMTest_HungarianLongWalk = class(TKMTest)
  protected
    procedure DoTick(aTick: Cardinal; var aKeepGoing: Boolean); override;
    procedure SetUp; override;
    procedure CheckResult; override;
    procedure TearDown; override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;


implementation
uses
  SysUtils,
  KM_Defaults, KM_Points, KM_CommonUtils,
  KM_GameApp, KM_HandsCollection, KM_Terrain, KM_HandTypes,
  KM_ResTypes, KM_UnitGroup, KM_UnitGroupTypes;


{ TKMTest_HungarianLongWalk }
procedure TKMTest_HungarianLongWalk.SetUp;
begin
  inherited;

  DYNAMIC_TERRAIN := False;

  // The largest map the game allows, which is where the rearrangement costs get biggest
  gGameApp.NewGameEmptyMap(256, 256);

  // Player controlled, so that no AI general orders the group about
  gHands[0].HandType := hndHuman;

  // With it off the group is never rearranged and the test has nothing to walk into
  FEAT_HUNGARIAN_GROUP_ORDER := True;

  // 300 men in 15 ranks, standing in the top left corner
  gHands[0].AddUnitGroup(utBowman, KMPoint(20, 20), dirE, 20, 300);
end;


procedure TKMTest_HungarianLongWalk.TearDown;
begin
  inherited;
  DYNAMIC_TERRAIN := True;
end;


procedure TKMTest_HungarianLongWalk.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
var
  canBeReached: Boolean;
begin
  // Let the group settle first, then send it to the opposite corner
  if aTick <> 10 then Exit;

  var group := gHands[0].UnitGroups[0];

  // Add up the diagonal of the cost matrix the group is about to hand the solver. That is the
  // accumulator which used to overflow, so the test has to know it gets past MaxInt
  var costSum: Int64 := 0;
  for var I := 1 to group.Count - 1 do
  begin
    var slot := GetPositionInGroup2(240, 240, dirS, I, group.UnitsPerRow, gTerrain.MapX, gTerrain.MapY, canBeReached);
    costSum := costSum + Round(Sqr(10 * slot.GetLengthDiag(group.Members[I].Position)));
  end;
  AssertTrue(costSum > MaxInt, Format('Costs add up to %d, which still fits Integer', [costSum]));

  group.OrderWalk(KMPoint(240, 240), True, wtokPlayerOrder, dirS);

  aKeepGoing := False;
end;


procedure TKMTest_HungarianLongWalk.CheckResult;
begin
  var group := gHands[0].UnitGroups[0];

  AssertTrue(group.Order = goWalkTo, 'Group should have taken the walk order');
  AssertEquals(300, group.Count, 'Group should have kept all its men');
end;


class function TKMTest_HungarianLongWalk.TestTags: TKMTestTagSet;
begin
  Result := [tcBowman, tcCombat, tcPathfinding];
end;


class function TKMTest_HungarianLongWalk.TestDescription: string;
begin
  Result := 'Tests a large group''s ability to walk across a big map without overflowing the formation solver.';
end;


initialization
  RegisterTest(TKMTest_HungarianLongWalk);
end.
