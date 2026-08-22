unit KM_Test_Archers_GoFar;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;


type
  // Two archer squads shoot it out 6 tiles apart, 21 per rank, 6 ranks deep.
  // A member's index in fMembers is his formation slot, and deaths shift those indexes.
  // Fails when an archer walks 10+ tiles to a spot a comrade stands twice nearer.
  TKMTest_ArchersGoFar = class(TKMTest)
  private
    procedure CheckWalkOrders(aTick: Cardinal);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    function DoTick(aTick: Cardinal): Boolean; override;
    procedure CheckResult; override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;


implementation
uses
  Math, SysUtils, TypInfo,
  KM_Defaults, KM_Points,
  KM_GameApp, KM_HandsCollection, KM_HandTypes, KM_Viewport,
  KM_Units, KM_UnitWarrior, KM_UnitGroup, KM_UnitGroupTypes, KM_UnitActionWalkTo;


const
  // Gap between the front ranks. Bowman range is 4..10.99, so both can shoot
  ARMIES_GAP = 6;

  // The longest walk an archer can legitimately be ordered to make in this setup
  MAX_WALK_DIST = 10;


// Distance from aLoc to the nearest other member of aUnit's group, MaxSingle if none
function NearestComrade(aHand: Integer; aUnit: TKMUnit; const aLoc: TKMPoint; out aUID: Integer): Single;
begin
  Result := MaxSingle;
  aUID := 0;

  var group := gHands[aHand].UnitGroups.GetGroupByMember(TKMUnitWarrior(aUnit));
  if group = nil then Exit;

  for var I := 0 to group.Count - 1 do
  if group.Members[I] <> aUnit then
  begin
    var d := KMLengthDiag(group.Members[I].Position, aLoc);
    if d < Result then
    begin
      Result := d;
      aUID := group.Members[I].UID;
    end;
  end;
end;


// Group state behind a far walk order, so a red run reads without a debugger
function DescribeFarWalk(aTick: Cardinal; aHand: Integer; aUnit: TKMUnit; const aWalkTo: TKMPoint;
                         aDist, aNearest: Single; aNearestUID: Integer): string;
begin
  Result := Format('Tick %d: archer %d of hand %d standing at %s was ordered to walk to %s, %.1f tiles away',
                   [aTick, aUnit.UID, aHand, TypeToString(aUnit.Position), TypeToString(aWalkTo), aDist]);

  var group := gHands[aHand].UnitGroups.GetGroupByMember(TKMUnitWarrior(aUnit));
  if group = nil then Exit;

  var idx := -1;
  for var I := 0 to group.Count - 1 do
    if group.Members[I] = aUnit then
      idx := I;

  Result := Result + Format('. Group %d: he is member %d of %d, %d per row, order %s at %s.'
                          + ' Comrade %d stands only %.1f tiles from that spot',
                            [group.UID, idx, group.Count, group.UnitsPerRow,
                             GetEnumName(TypeInfo(TKMGroupOrder), Integer(group.Order)),
                             TypeToString(group.OrderLoc), aNearestUID, aNearest]);
end;


{ TKMTest_ArchersGoFar }
procedure TKMTest_ArchersGoFar.SetUp;
begin
  inherited;

  DYNAMIC_TERRAIN := False;

  // Draw walk routes, so far walks can be seen in the test runner
  SHOW_UNIT_ROUTES := True;

  // 3 minutes of game time, arrows start flying within the first few ticks
  fDuration := 3 * 600;

  gGameApp.NewGameEmptyMap(64, 64);

  // Pull the camera out to fit both squads and their routes into view
  if (gGameApp.Game <> nil) and (gGameApp.Game.ActiveInterface <> nil) then
  begin
    var viewport := gGameApp.Game.ActiveInterface.Viewport;
    viewport.Zoom := viewport.Zoom / 2;
  end;

  // Player controlled, so that no AI general orders the squads about
  gHands[0].HandType := hndHuman;
  gHands[1].HandType := hndHuman;

  // An odd rank centres the leader, so both formations line up exactly
  var leader0 := KMPoint(29, 32);
  var leader1 := KMPoint(leader0.X + ARMIES_GAP, leader0.Y);

  var group0 := gHands[0].AddUnitGroup(utBowman, leader0, dirE, 21, 21 * 6);
  var group1 := gHands[1].AddUnitGroup(utBowman, leader1, dirW, 21, 21 * 6);

  group0.OrderAttackUnit(group1.Members[0], True);
  group1.OrderAttackUnit(group0.Members[0], True);
end;


procedure TKMTest_ArchersGoFar.TearDown;
begin
  inherited;
  DYNAMIC_TERRAIN := True;
  SHOW_UNIT_ROUTES := False;
end;


// Nobody should cross the battlefield while the two squads shoot at each other
procedure TKMTest_ArchersGoFar.CheckWalkOrders(aTick: Cardinal);
begin
  for var H := 0 to gHands.Count - 1 do
    for var I := 0 to gHands[H].Units.Count - 1 do
    begin
      var U := gHands[H].Units[I];

      if (U = nil) or U.IsDeadOrDying then Continue;
      if not (U.Action is TKMUnitActionWalkTo) then Continue;

      var walkTo := TKMUnitActionWalkTo(U.Action).WalkTo;
      var dist := KMLengthDiag(U.Position, walkTo);

      if dist <= MAX_WALK_DIST then Continue;

      //Only a mistake when a comrade stands at least twice as close to that spot
      var comradeUID: Integer;
      var nearest := NearestComrade(H, U, walkTo, comradeUID);
      if nearest * 2 > dist then Continue;

      var s := DescribeFarWalk(aTick, H, U, walkTo, dist, nearest, comradeUID);
      AssertTrue(False, s);
    end;
end;


function TKMTest_ArchersGoFar.DoTick(aTick: Cardinal): Boolean;
begin
  CheckWalkOrders(aTick);

  // Continue simulation (True) until one of the squads is wiped out
  Result := (gHands[0].Stats.GetUnitQty(utAny) > 0) and (gHands[1].Stats.GetUnitQty(utAny) > 0);
end;


procedure TKMTest_ArchersGoFar.CheckResult;
begin
  // Nothing to check at the end, walk orders are checked as they are given
end;


class function TKMTest_ArchersGoFar.TestTags: TKMTestTagSet;
begin
  Result := [tcBowman, tcCombat, tcPathfinding];
end;


class function TKMTest_ArchersGoFar.TestDescription: string;
begin
  Result := 'Archers in a firefight should not be ordered to walk across the whole battlefield.';
end;


initialization
  RegisterTest(TKMTest_ArchersGoFar);
end.
