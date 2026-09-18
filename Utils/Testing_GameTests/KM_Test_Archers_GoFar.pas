unit KM_Test_Archers_GoFar;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;


type
  // Two big archer groups shoot at each other.
  // A long walk is fine on its own, the whole squad could be shifting. Fail when it is
  // wasteful: another archer, walking himself, would have halved it by trading destinations.
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


function GetWalkTarget(aUnit: TKMUnit): TKMPoint;
begin
  Result := TKMUnitActionWalkTo(aUnit.Action).WalkTo;
end;


function FindBetterSwapPartner(aUnit: TKMUnit): TKMUnit;
begin
  Result := nil;

  var group := gHands[aUnit.Owner].UnitGroups.GetGroupByMember(TKMUnitWarrior(aUnit));

  if aUnit = group.FlagBearer then Exit;

  var ourWalkTo := GetWalkTarget(aUnit);
  var ourDistance := aUnit.Position.GetLengthDiag(ourWalkTo);

  for var I := 1 to group.Count - 1 do
  begin
    var U := group.Members[I];
    if U = aUnit then Continue;

    // Archers standing still are shooting, so only those already walking can trade destinations with us
    if not (U.Action is TKMUnitActionWalkTo) then Continue;

    var unitWalkTo := GetWalkTarget(U);
    var worstNow := Max(ourDistance, U.Position.GetLengthDiag(unitWalkTo));
    var worstSwapped := Max(aUnit.Position.GetLengthDiag(unitWalkTo), U.Position.GetLengthDiag(ourWalkTo));

    if worstSwapped * 2 <= worstNow then
      Exit(U);
  end;
end;


function DescribeSwap(aTick: Cardinal; aUnit, aPartner: TKMUnit): string;
begin
  var ourWalkTo := GetWalkTarget(aUnit);
  var hisWalkTo := GetWalkTarget(aPartner);
  var group := gHands[aUnit.Owner].UnitGroups.GetGroupByMember(TKMUnitWarrior(aUnit));

  Result := Format('Tick %d: archer %d of hand %d walks %.1f tiles from %s to %s, while member %d walks %.1f tiles from %s to %s. ' +
                   'Swapped, those walks would be %.1f and %.1f tiles. Group %d has %d members, %d per row, order %s at %s',
    [aTick, aUnit.UID, aUnit.Owner, aUnit.Position.GetLengthDiag(ourWalkTo), aUnit.Position.ToString, ourWalkTo.ToString,
     aPartner.UID, aPartner.Position.GetLengthDiag(hisWalkTo), aPartner.Position.ToString, hisWalkTo.ToString,
     aUnit.Position.GetLengthDiag(hisWalkTo), aPartner.Position.GetLengthDiag(ourWalkTo),
     group.UID, group.Count, group.UnitsPerRow, GetEnumName(TypeInfo(TKMGroupOrder), Integer(group.Order)), group.OrderLoc.ToString]);
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

      if U.Position.GetLengthDiag(GetWalkTarget(U)) <= MAX_WALK_DIST then Continue;

      var partner := FindBetterSwapPartner(U);
      if partner <> nil then
        AssertFail(DescribeSwap(aTick, U, partner));
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
