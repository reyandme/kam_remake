unit KM_Test_ClosestTile_Contract;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;


type
  // Pins down what GetClosestTile promises its callers, on plain grass where every tile is walk
  // connected: a free reachable target comes back as is, and a target somebody else stands on
  // gets traded for a free tile next to it.
  TKMTest_ClosestTileContract = class(TKMTest)
  private const
    ORIGIN_X = 20;  ORIGIN_Y = 20;  // Where our own unit stands
    FREE_X   = 40;  FREE_Y   = 40;  // Empty tile with nobody around it
    BUSY_X   = 40;  BUSY_Y   = 20;  // Tile with another unit standing on it
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
  KM_Defaults, KM_Points,
  KM_GameApp, KM_HandsCollection, KM_HandTypes, KM_Terrain,
  KM_UnitWarrior;


{ TKMTest_ClosestTileContract }
procedure TKMTest_ClosestTileContract.SetUp;
begin
  inherited;

  DYNAMIC_TERRAIN := False;

  // Terrain is fully prepared here, one tick is enough
  fDuration := 5;

  gGameApp.NewGameEmptyMap(64, 64);

  // Player controlled, so that no AI general orders the squads about
  gHands[0].HandType := hndHuman;

  // Warriors need a group, CheckForEnemy calls OnPickedFight without an Assigned check
  var origin := TKMUnitWarrior(gHands[0].AddUnit(utAxeFighter, KMPoint(ORIGIN_X, ORIGIN_Y), False));
  gHands[0].UnitGroups.AddGroup(origin);

  // Stands right on top of the busy target tile
  var blocker := TKMUnitWarrior(gHands[0].AddUnit(utAxeFighter, KMPoint(BUSY_X, BUSY_Y), False));
  gHands[0].UnitGroups.AddGroup(blocker);
end;


procedure TKMTest_ClosestTileContract.TearDown;
begin
  inherited;
  DYNAMIC_TERRAIN := True;
end;


procedure TKMTest_ClosestTileContract.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  aKeepGoing := False; // Nothing to simulate

  var origin := KMPoint(ORIGIN_X, ORIGIN_Y);
  var freeLoc := KMPoint(FREE_X, FREE_Y);
  var busyLoc := KMPoint(BUSY_X, BUSY_Y);

  // Check the setup itself, so a misplaced unit does not make the test pass silently
  AssertTrue(gTerrain.HasUnit(origin), 'Setup: our own unit should stand on the origin tile');
  AssertTrue(not gTerrain.HasUnit(freeLoc), 'Setup: the free target tile should be empty');
  AssertTrue(gTerrain.HasUnit(busyLoc), 'Setup: the busy target tile should be taken by another unit');
  AssertTrue(gTerrain.RouteCanBeMade(origin, freeLoc, tpWalk), 'Setup: the free target should be reachable');

  // Free, walkable, walk connected target - there is nothing better to offer
  var res := gTerrain.GetClosestTile(freeLoc, origin, tpWalk, False);
  AssertTrue(KMSamePoint(res, freeLoc),
    Format('GetClosestTile(target %s, origin %s) returned %s instead of the free target itself',
           [freeLoc.ToString, origin.ToString, res.ToString]));

  // Target taken by another unit - we are low priority, so we do not bump important units
  res := gTerrain.GetClosestTile(busyLoc, origin, tpWalk, False);
  AssertTrue(not KMSamePoint(res, busyLoc),
    Format('GetClosestTile(target %s) returned the very tile another unit stands on', [busyLoc.ToString]));
  AssertTrue(not gTerrain.HasUnit(res),
    Format('GetClosestTile(target %s) returned %s, which is taken by another unit', [busyLoc.ToString, res.ToString]));
  AssertTrue(res.GetLengthDiag(busyLoc) <= 2,
    Format('GetClosestTile(target %s) returned %s, too far away to be the closest free tile', [busyLoc.ToString, res.ToString]));

  // The aAcceptTargetLoc shortcut above the loop
  res := gTerrain.GetClosestTile(freeLoc, origin, tpWalk, True);
  AssertTrue(KMSamePoint(res, freeLoc),
    Format('GetClosestTile(target %s, aAcceptTargetLoc = True) returned %s', [freeLoc.ToString, res.ToString]));
end;


procedure TKMTest_ClosestTileContract.CheckResult;
begin
  // Everything is checked on the first tick
end;


class function TKMTest_ClosestTileContract.TestTags: TKMTestTagSet;
begin
  Result := [tcPathfinding];
end;


class function TKMTest_ClosestTileContract.TestDescription: string;
begin
  Result := 'GetClosestTile should return a free reachable tile, never one taken by another unit.';
end;


initialization
  RegisterTest(TKMTest_ClosestTileContract);
end.
