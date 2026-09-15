unit KM_Test_Archers_GoFar;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;


type
  // Two big archer groups shoot at each other.
  // Archers keep taking new spots as their ranks thin out, so a long walk is fine on its
  // own - the whole squad could be shifting. Fail when the walk is plain wasteful:
  // another archer would have reached that spot for less than half the effort,
  // and ours would have reached his, had the two simply swapped destinations.
  TKMTest_ArchersGoFar = class(TKMTest)
  private const
    MAX_WALK_DIST = 10;

    procedure CheckWalkOrders(aTick: Cardinal);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    procedure DoTick(aTick: Cardinal; var aKeepGoing: Boolean); override;
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


// Someone whose walk crosses ours, so that trading destinations would halve the longer of the two.
// Only archers already on the move can trade - the ones standing still are shooting,
// and sending them off means two archers walking where one walked before
function BetterSwapPartner(aUnit: TKMUnit; const aWalkTo: TKMPoint): TKMUnit;
begin
  Result := nil;

  var group := gHands[aUnit.Owner].UnitGroups.GetGroupByMember(TKMUnitWarrior(aUnit));

  // The flag bearer keeps his spot in the formation, he is not ours to swap around
  if (group = nil) or (group.Members[0] = aUnit) then Exit;

  var ourDist := aUnit.Position.GetLengthDiag(aWalkTo);

  for var I := 1 to group.Count - 1 do
  begin
    var U := group.Members[I];
    if (U = aUnit) or not (U.Action is TKMUnitActionWalkTo) then Continue;

    var hisWalkTo := TKMUnitActionWalkTo(U.Action).WalkTo;
    var worstNow := Max(ourDist, U.Position.GetLengthDiag(hisWalkTo));
    var worstSwapped := Max(aUnit.Position.GetLengthDiag(hisWalkTo), U.Position.GetLengthDiag(aWalkTo));

    if worstSwapped * 2 <= worstNow then
      Exit(U);
  end;
end;


function DescribeSwap(aTick: Cardinal; aHand: Integer; aUnit: TKMUnit; const aWalkTo: TKMPoint; aPartner: TKMUnit): string;
begin
  var hisWalkTo := TKMUnitActionWalkTo(aPartner.Action).WalkTo;

  Result := Format('Tick %d: archer %d of hand %d standing at %s was ordered to walk to %s, %.1f tiles away, ' +
                   'while member %d standing at %s walks to %s, %.1f tiles away. Swapped, those walks would be %.1f and %.1f tiles',
    [aTick, aUnit.UID, aHand, aUnit.Position.ToString, aWalkTo.ToString, aUnit.Position.GetLengthDiag(aWalkTo),
     aPartner.UID, aPartner.Position.ToString, hisWalkTo.ToString, aPartner.Position.GetLengthDiag(hisWalkTo),
     aUnit.Position.GetLengthDiag(hisWalkTo), aPartner.Position.GetLengthDiag(aWalkTo)]);

  var group := gHands[aHand].UnitGroups.GetGroupByMember(TKMUnitWarrior(aUnit));

  var idx := -1;
  for var I := 0 to group.Count - 1 do
    if group.Members[I] = aUnit then
      idx := I;

  Result := Result + Format('. Group %d: he is member %d of %d, %d per row, order %s at %s',
    [group.UID, idx, group.Count, group.UnitsPerRow, GetEnumName(TypeInfo(TKMGroupOrder), Integer(group.Order)), group.OrderLoc.ToString]);
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
      if U.Position.GetLengthDiag(walkTo) <= MAX_WALK_DIST then Continue;

      var partner := BetterSwapPartner(U, walkTo);
      if partner = nil then Continue;

      AssertTrue(False, DescribeSwap(aTick, I, U, walkTo, partner));
    end;
end;


procedure TKMTest_ArchersGoFar.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  CheckWalkOrders(aTick);

  // Continue simulation (True) until one of the squads is wiped out
  aKeepGoing := (gHands[0].Stats.GetUnitQty(utAny) > 0) and (gHands[1].Stats.GetUnitQty(utAny) > 0);
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
  Result := 'Archers in a firefight should not take a long walk that a comrade would make in half the steps.';
end;


initialization
  RegisterTest(TKMTest_ArchersGoFar);
end.
