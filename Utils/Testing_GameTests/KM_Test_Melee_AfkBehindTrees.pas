unit KM_Test_Melee_AfkBehindTrees;
{$I KaM_Remake.inc}
interface
uses
  KM_Points, KM_UnitGroup, KM_Test;


type
  // The case Krom asked for in PR #290: 8 trees with 2 knights of one hand and 1 knight
  // of another hand around them.
  //
  // Trees turned out not to fit this role: `data/defines/mapelem.dat` gives every chopable
  // tree, at every growth stage, AllBlocked = False - a unit can walk straight onto a tree's
  // tile, only diagonal cuts across it are blocked (DiagonalBlocked). GetClosestTile (the
  // function PR #290 rewrites) never looks at diagonal blocking at all, only CheckPassability,
  // the WalkConnect group and HasUnit - so no arrangement of trees can wall anything off for it.
  // The pocket wall here is water instead (as in the already-merged KM_Test_Walk_UnwalkableTarget);
  // the 8 trees are planted along the approach purely as the scenery Krom's screenshot showed,
  // and play no part in the mechanism.
  //
  // The lone enemy knight sits in a pocket that has a single entrance, so only one of the two
  // attackers can reach him. The second one has nothing better to do than to wait next to his
  // fighting comrade, ready to take his place.
  //
  // Instead he walks around to the opposite side of the pocket and stands there for the rest
  // of the fight. TKMUnitGroup.CheckForFight keeps handing him
  // OrderWalk(offender.PositionNext, False), GetClosestTile spirals out from the enemy tile,
  // every tile around the enemy is either water or taken by his comrade, and the first tile
  // of the next ring is the one he is standing on himself - which the
  // "not HasUnit(T) or KMSamePoint(T, aOriginLoc)" half of the occupancy check accepts.
  // GetClosestTile returns his own position, TakeNextOrder skips SetActionWalkToSpot,
  // and the knight is afk until his comrade dies
  TKMTest_MeleeAfkBehindTrees = class(TKMTest)
  private const
    // Enemy knight sits here, walled in with a single entrance from the south
    ENEMY_X = 32;
    ENEMY_Y = 32;
    // Attacking group spawns south of the pocket
    ATTACKERS_X = 32;
    ATTACKERS_Y = 36;
    // Give the group time to settle before the order, same as in other walk tests
    ORDER_TICK = 10;
    // How long a member may stand still before we call him afk (10 sec of game time)
    MAX_IDLE_TICKS = 100;
    // A member who is not fighting himself is expected to wait within this range of the one who is
    HELP_RANGE = 2;
  private
    fWater: array [0..7] of TKMPoint;
    fTrees: array [0..7] of TKMPoint;
    fAttackers: TKMUnitGroup;
    fDefenders: TKMUnitGroup;
    fFightStarted: Boolean;
    fWatchUID: array [0..1] of Integer;
    fWatchLoc: array [0..1] of TKMPoint;
    fWatchIdle: array [0..1] of Integer;
    fFailure: string;
    procedure PlantTree(const aLoc: TKMPoint);
    function WatchIndex(aUID: Integer): Integer;
    function FightingComradeLoc(aUID: Integer; out aLoc: TKMPoint): Boolean;
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
  SysUtils,
  KM_Defaults, KM_Terrain,
  KM_GameApp, KM_HandsCollection, KM_HandTypes,
  KM_ResMapElements, KM_ResTilesetTypes, KM_ResTypes, KM_UnitWarrior;


{ TKMTest_MeleeAfkBehindTrees }
// Decorative only - see the AllBlocked note on the class comment. Planted well clear of
// the pocket and its approach so it can never interfere with what the test actually checks
procedure TKMTest_MeleeAfkBehindTrees.PlantTree(const aLoc: TKMPoint);
var
  treeObjID: Integer;
begin
  treeObjID := gTerrain.ChooseTreeToPlace(aLoc, caAgeFull, True);
  gTerrain.SetObject(aLoc, treeObjID);
  gTerrain.Land[aLoc.Y, aLoc.X].TreeAge := TREE_AGE_FULL;
end;


procedure TKMTest_MeleeAfkBehindTrees.SetUp;
begin
  inherited;

  DYNAMIC_TERRAIN := False;

  gGameApp.NewGameEmptyMap(64, 64);

  if gGameApp.Game.ActiveInterface <> nil then
  begin
    gGameApp.Game.ActiveInterface.Viewport.Zoom := 2;
    gGameApp.Game.ActiveInterface.Viewport.Position := KMPointF(ENEMY_X, ENEMY_Y + 2);
  end;

  // Player controlled, so that no AI general orders the squads about
  gHands[0].HandType := hndHuman;
  gHands[1].HandType := hndHuman;

  // Water walls the enemy tile in. Every neighbour of it is water, except for the entrance
  // to the south; the last tile extends the west wall past the entrance so a unit can't just
  // slip around the corner. Water genuinely fails CheckPassability(tpWalk), unlike a tree
  fWater[0] := KMPoint(ENEMY_X - 1, ENEMY_Y - 1);
  fWater[1] := KMPoint(ENEMY_X,     ENEMY_Y - 1);
  fWater[2] := KMPoint(ENEMY_X + 1, ENEMY_Y - 1);
  fWater[3] := KMPoint(ENEMY_X - 1, ENEMY_Y);
  fWater[4] := KMPoint(ENEMY_X + 1, ENEMY_Y);
  fWater[5] := KMPoint(ENEMY_X - 1, ENEMY_Y + 1);
  fWater[6] := KMPoint(ENEMY_X + 1, ENEMY_Y + 1);
  fWater[7] := KMPoint(ENEMY_X - 1, ENEMY_Y + 2);

  for var I := Low(fWater) to High(fWater) do
  begin
    AssertTrue(gTerrain.ScriptTrySetTile(fWater[I].X, fWater[I].Y, BASE_TERRAIN[tkWater], 0),
      Format('Setup: could not turn %s into water', [fWater[I].ToString]));
    AssertTrue(not gTerrain.CheckPassability(fWater[I], tpWalk),
      Format('Setup: water at %s should have blocked the tile', [fWater[I].ToString]));
  end;

  // The single way in and the way up to it have to stay open
  AssertTrue(gTerrain.CheckPassability(KMPoint(ENEMY_X, ENEMY_Y + 1), tpWalk), 'Setup: the pocket entrance should be walkable');
  AssertTrue(gTerrain.CheckPassability(KMPoint(ENEMY_X, ENEMY_Y + 2), tpWalk), 'Setup: the approach to the pocket should be walkable');

  // 8 decorative trees, matching Krom's screenshot, dotted around the approach well clear
  // of the water and of every tile a unit in this test could stand on
  fTrees[0] := KMPoint(ENEMY_X - 3, ENEMY_Y - 1);
  fTrees[1] := KMPoint(ENEMY_X + 3, ENEMY_Y - 1);
  fTrees[2] := KMPoint(ENEMY_X - 3, ENEMY_Y + 1);
  fTrees[3] := KMPoint(ENEMY_X + 3, ENEMY_Y + 1);
  fTrees[4] := KMPoint(ENEMY_X - 3, ENEMY_Y + 3);
  fTrees[5] := KMPoint(ENEMY_X + 3, ENEMY_Y + 3);
  fTrees[6] := KMPoint(ENEMY_X - 3, ENEMY_Y + 5);
  fTrees[7] := KMPoint(ENEMY_X + 3, ENEMY_Y + 5);

  for var I := Low(fTrees) to High(fTrees) do
    PlantTree(fTrees[I]);

  fDefenders := gHands[1].AddUnitGroup(utKnight, KMPoint(ENEMY_X, ENEMY_Y), dirS, 1, 1);
  fAttackers := gHands[0].AddUnitGroup(utKnight, KMPoint(ATTACKERS_X, ATTACKERS_Y), dirN, 2, 2);

  AssertTrue(fDefenders <> nil, 'Setup: the enemy group was not created');
  AssertTrue(fAttackers <> nil, 'Setup: the attacking group was not created');
  AssertEquals(1, fDefenders.Count, 'Setup: the enemy knight should have been placed inside the pocket');
  AssertEquals(2, fAttackers.Count, 'Setup: both attacking knights should have been placed');

  for var I := 0 to fAttackers.Count - 1 do
  begin
    fWatchUID[I] := fAttackers.Members[I].UID;
    fWatchLoc[I] := fAttackers.Members[I].Position;
  end;
end;


procedure TKMTest_MeleeAfkBehindTrees.TearDown;
begin
  inherited;
  DYNAMIC_TERRAIN := True;
end;


function TKMTest_MeleeAfkBehindTrees.WatchIndex(aUID: Integer): Integer;
begin
  for var I := Low(fWatchUID) to High(fWatchUID) do
    if fWatchUID[I] = aUID then
      Exit(I);

  Result := -1;
end;


// Position of any other member of the group that is fighting right now
function TKMTest_MeleeAfkBehindTrees.FightingComradeLoc(aUID: Integer; out aLoc: TKMPoint): Boolean;
begin
  Result := False;

  for var I := 0 to fAttackers.Count - 1 do
  begin
    var member := fAttackers.Members[I];
    if (member.UID <> aUID) and not member.IsDeadOrDying and member.InFight then
    begin
      aLoc := member.Position;
      Exit(True);
    end;
  end;
end;


procedure TKMTest_MeleeAfkBehindTrees.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
var
  comradeLoc: TKMPoint;
begin
  if aTick = ORDER_TICK then
    fAttackers.OrderAttackUnit(fDefenders.FlagBearer, True);

  // Fight is over, nothing left to watch. Checked through the stats, because a group
  // that lost its last member is freed and our field would be dangling by now
  if (gHands[0].Stats.GetUnitQty(utAny) = 0) or (gHands[1].Stats.GetUnitQty(utAny) = 0) then
  begin
    aKeepGoing := False;
    Exit;
  end;

  fFightStarted := fFightStarted or fAttackers.InFight;

  // Only members who could join the fight are of interest, so start counting once it is on
  if not fFightStarted then Exit;

  for var I := 0 to fAttackers.Count - 1 do
  begin
    var member := fAttackers.Members[I];
    if member.IsDeadOrDying then Continue;

    var W := WatchIndex(member.UID);
    if W = -1 then Continue;

    var memberLoc := member.Position;

    if member.InFight or not KMSamePoint(memberLoc, fWatchLoc[W]) then
    begin
      fWatchLoc[W] := memberLoc;
      fWatchIdle[W] := 0;
      Continue;
    end;

    Inc(fWatchIdle[W]);
    if fWatchIdle[W] < MAX_IDLE_TICKS then Continue;

    // Standing still is fine while there is no fight to join, it is only afk when
    // a comrade is fighting and we are nowhere near him to take over
    if not FightingComradeLoc(member.UID, comradeLoc) then Continue;
    if memberLoc.GetLengthDiag(comradeLoc) <= HELP_RANGE then Continue;

    fFailure := Format('Tick %d: knight %d has been standing idle at %s for %d ticks, %.1f tiles away from his comrade fighting at %s',
                       [aTick, member.UID, memberLoc.ToString, fWatchIdle[W],
                        memberLoc.GetLengthDiag(comradeLoc), comradeLoc.ToString]);
    aKeepGoing := False;
    Exit;
  end;
end;


procedure TKMTest_MeleeAfkBehindTrees.CheckResult;
begin
  AssertTrue(fFightStarted, 'Attackers never reached the enemy knight, the test proves nothing');
  AssertTrue(fFailure = '', fFailure);
end;


class function TKMTest_MeleeAfkBehindTrees.TestTags: TKMTestTagSet;
begin
  Result := [tcKnight, tcCombat, tcPathfinding];
end;


class function TKMTest_MeleeAfkBehindTrees.TestDescription: string;
begin
  Result := 'A knight who cannot fit next to the enemy should wait by his fighting comrade, not stand afk elsewhere.';
end;


initialization
  RegisterTest(TKMTest_MeleeAfkBehindTrees);
end.
