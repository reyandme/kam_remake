unit KM_Test_Walk_UnwalkableTarget;
{$I KaM_Remake.inc}
interface
uses
  KM_Points, KM_UnitGroup, KM_UnitWarrior, KM_Test;


type
  // A lone soldier is ordered onto a pond. His formation slot is not walkable, so OrderWalk passes
  // Exact = False on to GetClosestTile, which has to find him a spot on the shore - and this time
  // there is nobody standing around the target for the search to pick from.
  TKMTest_WalkUnwalkableTarget = class(TKMTest)
  private const
    WATER_X = 30;
    WATER_Y = 30;
    START_X = 30;
    START_Y = 36;
    ORDER_TICK = 20; // Units start with a 10 tick Stay action, let them settle first
  private
    fGroup: TKMUnitGroup;
    fWarrior: TKMUnitWarrior;
    fStartLoc: TKMPoint;
    fWaterPainted: Boolean;
    fReacted: Boolean;
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
  KM_ResTilesetTypes, KM_UnitActionWalkTo, KM_UnitGroupTypes;


{ TKMTest_WalkUnwalkableTarget }
procedure TKMTest_WalkUnwalkableTarget.SetUp;
begin
  inherited;

  DYNAMIC_TERRAIN := False;
  SHOW_UNIT_ROUTES := True;

  fDuration := 300;

  gGameApp.NewGameEmptyMap(64, 64);

  if gGameApp.Game.ActiveInterface <> nil then
  begin
    gGameApp.Game.ActiveInterface.Viewport.Zoom := 2;
    gGameApp.Game.ActiveInterface.Viewport.Position := KMPointF(WATER_X, WATER_Y + 3);
  end;

  // Player controlled, so that no AI general orders the squads about
  gHands[0].HandType := hndHuman;

  // 3x3, so that the centre is unwalkable beyond any doubt
  fWaterPainted := True;
  for var I := -1 to 1 do
    for var K := -1 to 1 do
      fWaterPainted := gTerrain.ScriptTrySetTile(WATER_X + K, WATER_Y + I, BASE_TERRAIN[tkWater], 0)
                       and fWaterPainted;

  fStartLoc := KMPoint(START_X, START_Y);
  fWarrior := TKMUnitWarrior(gHands[0].AddUnit(utAxeFighter, fStartLoc, False));
  fGroup := gHands[0].UnitGroups.AddGroup(fWarrior);
end;


procedure TKMTest_WalkUnwalkableTarget.TearDown;
begin
  inherited;
  DYNAMIC_TERRAIN := True;
  SHOW_UNIT_ROUTES := False;
end;


procedure TKMTest_WalkUnwalkableTarget.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  // The same call the player's "walk here" order ends up in
  if aTick = ORDER_TICK then
    fGroup.OrderWalk(KMPoint(WATER_X, WATER_Y), True, wtokPlayerOrder);

  if aTick > ORDER_TICK then
    fReacted := fReacted
                or (fWarrior.Action is TKMUnitActionWalkTo)
                or not KMSamePoint(fWarrior.Position, fStartLoc);

  aKeepGoing := not fReacted;
end;


procedure TKMTest_WalkUnwalkableTarget.CheckResult;
begin
  // Check the setup itself, so a failed paint does not make the test pass silently
  AssertTrue(fWaterPainted, 'Setup: failed to paint the water patch');
  AssertTrue(not gTerrain.CheckPassability(KMPoint(WATER_X, WATER_Y), tpWalk),
    'Setup: the ordered tile was expected to be unwalkable water');
  AssertTrue(gTerrain.RouteCanBeMade(fStartLoc, KMPoint(WATER_X, WATER_Y - 2), tpWalk),
    'Setup: there should be reachable dry ground right behind the pond');

  AssertTrue(fReacted,
    Format('Axe fighter %d was ordered onto the water at %d:%d and stayed put at %s '
         + 'for the whole run, instead of walking up to the shore',
           [fWarrior.UID, WATER_X, WATER_Y, fStartLoc.ToString]));
end;


class function TKMTest_WalkUnwalkableTarget.TestTags: TKMTestTagSet;
begin
  Result := [tcAxeFighter, tcPathfinding];
end;


class function TKMTest_WalkUnwalkableTarget.TestDescription: string;
begin
  Result := 'A soldier ordered onto unwalkable ground should walk to the closest tile he can stand on.';
end;


initialization
  RegisterTest(TKMTest_WalkUnwalkableTarget);
end.
