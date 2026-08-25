unit KM_Test_Walk_UnwalkableTarget;
{$I KaM_Remake.inc}
interface
uses
  KM_Points, KM_UnitGroup, KM_UnitWarrior, KM_Test;


type
  // Warrior should walk towards the target when the target cant be reacohed
  TKMTest_WalkUnwalkableTarget = class(TKMTest)
  private const
    WATER_X = 30;
    WATER_Y = 30;
    START_X = 30;
    START_Y = 36;
  private
    fGroup: TKMUnitGroup;
    fStartLoc: TKMPoint;
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

  fDuration := 30;

  gGameApp.NewGameEmptyMap(64, 64);

  if gGameApp.Game.ActiveInterface <> nil then
  begin
    gGameApp.Game.ActiveInterface.Viewport.Zoom := 2;
    gGameApp.Game.ActiveInterface.Viewport.Position := KMPointF(WATER_X, WATER_Y + 2);
  end;

  // Player controlled, so that no AI general orders the squads about
  gHands[0].HandType := hndHuman;

  for var I := -1 to 1 do
    for var K := -1 to 1 do
      gTerrain.ScriptTrySetTile(WATER_X + K, WATER_Y + I, BASE_TERRAIN[tkWater], 0);

  fStartLoc := KMPoint(START_X, START_Y);
  fGroup := gHands[0].AddUnitGroup(utAxeFighter, fStartLoc, dirN, 1, 1);
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
  if aTick = 10 then
    fGroup.OrderWalk(KMPoint(WATER_X, WATER_Y), True, wtokPlayerOrder);

  if aTick > 10 then
    fReacted := fReacted or (fGroup.FlagBearer.Action is TKMUnitActionWalkTo) or not KMSamePoint(fGroup.FlagBearer.Position, fStartLoc);

  aKeepGoing := not fReacted;
end;


procedure TKMTest_WalkUnwalkableTarget.CheckResult;
begin
  AssertTrue(fReacted, 'Warrior did not move');
end;


class function TKMTest_WalkUnwalkableTarget.TestTags: TKMTestTagSet;
begin
  Result := [tcAxeFighter, tcPathfinding];
end;


class function TKMTest_WalkUnwalkableTarget.TestDescription: string;
begin
  Result := 'A warrior ordered onto unwalkable ground should walk to the closest tile he can stand on.';
end;


initialization
  RegisterTest(TKMTest_WalkUnwalkableTarget);
end.
