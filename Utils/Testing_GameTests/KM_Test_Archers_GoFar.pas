unit KM_Test_Archers_GoFar;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;


type
  // Two big archer groups shoot at each other.
  // Fail when archers are reordered inefficiently - has to walk 10+ tiles
  // when there are much closer candidates.
  TKMTest_ArchersGoFar = class(TKMTest)
  private const
    MAX_WALK_DIST = 10;

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
  KM_GameApp, KM_HandsCollection, KM_HandTypes,
  KM_Units, KM_UnitWarrior, KM_UnitGroup, KM_UnitGroupTypes, KM_UnitActionWalkTo;


function NearestMember(aUnit: TKMUnit; const aTargetLoc: TKMPoint): TKMUnit;
begin
  Result := nil;

  var group := gHands[aUnit.Owner].UnitGroups.GetGroupByMember(TKMUnitWarrior(aUnit));

  var bestDist := MaxSingle;
  for var I := 0 to group.Count - 1 do
  if group.Members[I] <> aUnit then
  begin
    var U := group.Members[I];
    var newDist := U.Position.GetLengthDiag(aTargetLoc);
    if newDist < bestDist then
    begin
      bestDist := newDist;
      Result := U;
    end;
  end;
end;


function DescribeFarWalk(aTick: Cardinal; aHand: Integer; aUnit: TKMUnit; const aWalkTo: TKMPoint; aDist: Single; aMember: TKMUnit; aMemberDist: Single): string;
begin
  Result := Format('Tick %d: archer %d of hand %d standing at %s was ordered to walk to %s, %.1f tiles away',
    [aTick, aUnit.UID, aHand, aUnit.Position.ToString, aWalkTo.ToString, aDist]);

  var group := gHands[aHand].UnitGroups.GetGroupByMember(TKMUnitWarrior(aUnit));

  var idx := -1;
  for var I := 0 to group.Count - 1 do
    if group.Members[I] = aUnit then
      idx := I;

  Result := Result + Format('. Group %d: he is member %d of %d, %d per row, order %s at %s. Member %d stands only %.1f tiles from that spot',
    [group.UID, idx, group.Count, group.UnitsPerRow, GetEnumName(TypeInfo(TKMGroupOrder), Integer(group.Order)), group.OrderLoc.ToString, aMember.UID, aMemberDist]);
end;


{ TKMTest_ArchersGoFar }
procedure TKMTest_ArchersGoFar.SetUp;
begin
  inherited;

  DYNAMIC_TERRAIN := False;
  SHOW_UNIT_ROUTES := True;

  fDuration := 3 * 600;

  gGameApp.NewGameEmptyMap(64, 64);

  if gGameApp.Game.ActiveInterface <> nil then
    gGameApp.Game.ActiveInterface.Viewport.Zoom := 0.5;

  // Player controlled, so that no AI general orders the squads about
  gHands[0].HandType := hndHuman;
  gHands[1].HandType := hndHuman;

  var group0 := gHands[0].AddUnitGroup(utBowman, KMPoint(29, 32), dirE, 21, 21 * 6);
  var group1 := gHands[1].AddUnitGroup(utBowman, KMPoint(35, 32), dirW, 21, 21 * 6);

  group0.OrderAttackUnit(group1.Members[0], True);
  group1.OrderAttackUnit(group0.Members[0], True);
end;


procedure TKMTest_ArchersGoFar.TearDown;
begin
  inherited;
  DYNAMIC_TERRAIN := True;
  SHOW_UNIT_ROUTES := False;
end;


procedure TKMTest_ArchersGoFar.CheckWalkOrders(aTick: Cardinal);
begin
  for var I := 0 to gHands.Count - 1 do
    for var K := 0 to gHands[I].Units.Count - 1 do
    begin
      var U := gHands[I].Units[K];

      if (U = nil) or U.IsDeadOrDying then Continue;
      if not (U.Action is TKMUnitActionWalkTo) then Continue;

      var walkTo := TKMUnitActionWalkTo(U.Action).WalkTo;
      var ourDist := U.Position.GetLengthDiag(walkTo);

      if ourDist <= MAX_WALK_DIST then Continue;

      // Only an issue when a member stands at least twice as close to that spot
      var member := NearestMember(U, walkTo);
      var memberDist := member.Position.GetLengthDiag(walkTo);
      if memberDist * 2 > ourDist then Continue;

      var descText := DescribeFarWalk(aTick, I, U, walkTo, ourDist, member, memberDist);
      AssertTrue(False, descText);
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
