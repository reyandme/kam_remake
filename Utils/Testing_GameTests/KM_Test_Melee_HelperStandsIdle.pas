unit KM_Test_Melee_HelperStandsIdle;
{$I KaM_Remake.inc}
interface
uses
  KM_Points, KM_UnitGroup, KM_Test;


type
  // Kromster's screenshot on PR #290: 2 knights of one hand attack 1 knight of another, near
  // some trees. One attacker reaches the enemy and fights; the other should wait next to him,
  // ready to take his place, instead of wandering off and going idle.
  TKMTest_MeleeHelperStandsIdle = class(TKMTest)
  private const
    // Enemy knight sits here, walled in by water on every side but the south
    ENEMY_X = 32;
    ENEMY_Y = 32;
    ATTACKERS_X = 32;
    ATTACKERS_Y = 36;
    ORDER_TICK = 10;
    // How long the helper may stand still before we call it idle (10 sec of game time)
    MAX_IDLE_TICKS = 100;
    // The helper is expected to end up within this many tiles of the fight
    HELP_RANGE = 2;
  private
    fAttackers: TKMUnitGroup;
    fDefenders: TKMUnitGroup;
    fFightStarted: Boolean;
    fHelperLastLoc: TKMPoint;
    fHelperIdleTicks: Integer;
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


procedure PlantTree(const aLoc: TKMPoint);
var
  treeObjID: Integer;
begin
  treeObjID := gTerrain.ChooseTreeToPlace(aLoc, caAgeFull, True);
  gTerrain.SetObject(aLoc, treeObjID);
  gTerrain.Land[aLoc.Y, aLoc.X].TreeAge := TREE_AGE_FULL;
end;


// The attacker who isn't fighting is expected to stay close to the one who is
function FindHelper(aGroup: TKMUnitGroup; out aFighterLoc: TKMPoint): TKMUnitWarrior;
begin
  Result := nil;

  for var I := 0 to aGroup.Count - 1 do
  begin
    var member := aGroup.Members[I];
    if member.IsDeadOrDying then Continue;

    if member.InFight then
      aFighterLoc := member.Position
    else
      Result := member;
  end;
end;


{ TKMTest_MeleeHelperStandsIdle }
procedure TKMTest_MeleeHelperStandsIdle.SetUp;
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

  // Water on every side of the enemy but the south, plus one tile further so a unit can't
  // slip around the west corner into the entrance
  for var dX := -1 to 1 do
    for var dY := -1 to 1 do
      if (dX <> 0) or (dY <> 1) then
        gTerrain.ScriptTrySetTile(ENEMY_X + dX, ENEMY_Y + dY, BASE_TERRAIN[tkWater], 0);
  gTerrain.ScriptTrySetTile(ENEMY_X - 1, ENEMY_Y + 2, BASE_TERRAIN[tkWater], 0);

  // 8 trees, matching Kromster's screenshot, well clear of the water and the approach
  PlantTree(KMPoint(ENEMY_X - 3, ENEMY_Y - 1));
  PlantTree(KMPoint(ENEMY_X + 3, ENEMY_Y - 1));
  PlantTree(KMPoint(ENEMY_X - 3, ENEMY_Y + 1));
  PlantTree(KMPoint(ENEMY_X + 3, ENEMY_Y + 1));
  PlantTree(KMPoint(ENEMY_X - 3, ENEMY_Y + 3));
  PlantTree(KMPoint(ENEMY_X + 3, ENEMY_Y + 3));
  PlantTree(KMPoint(ENEMY_X - 3, ENEMY_Y + 5));
  PlantTree(KMPoint(ENEMY_X + 3, ENEMY_Y + 5));

  fDefenders := gHands[1].AddUnitGroup(utKnight, KMPoint(ENEMY_X, ENEMY_Y), dirS, 1, 1);
  fAttackers := gHands[0].AddUnitGroup(utKnight, KMPoint(ATTACKERS_X, ATTACKERS_Y), dirN, 2, 2);
end;


procedure TKMTest_MeleeHelperStandsIdle.TearDown;
begin
  inherited;
  DYNAMIC_TERRAIN := True;
end;


procedure TKMTest_MeleeHelperStandsIdle.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  if aTick = ORDER_TICK then
    fAttackers.OrderAttackUnit(fDefenders.FlagBearer, True);

  // Continue simulation (True) until one of the squads is wiped out
  aKeepGoing := (gHands[0].Stats.GetUnitQty(utAny) > 0) and (gHands[1].Stats.GetUnitQty(utAny) > 0);
  if not aKeepGoing then Exit;

  if not fAttackers.InFight then Exit;
  fFightStarted := True;

  var fighterLoc: TKMPoint;
  var helper := FindHelper(fAttackers, fighterLoc);
  if helper = nil then Exit; // both members are fighting somehow - nothing to watch

  if KMSamePoint(helper.Position, fHelperLastLoc) then
    Inc(fHelperIdleTicks)
  else
  begin
    fHelperLastLoc := helper.Position;
    fHelperIdleTicks := 0;
  end;

  if fHelperIdleTicks < MAX_IDLE_TICKS then Exit;

  var dist := helper.Position.GetLengthDiag(fighterLoc);
  AssertTrue(dist <= HELP_RANGE,
    Format('Tick %d: knight %d has been standing idle at %s for %d ticks, %.1f tiles from the fight at %s',
           [aTick, helper.UID, helper.Position.ToString, fHelperIdleTicks, dist, fighterLoc.ToString]));
end;


procedure TKMTest_MeleeHelperStandsIdle.CheckResult;
begin
  AssertTrue(fFightStarted, 'The attackers never engaged the enemy knight, so the test proved nothing');
end;


class function TKMTest_MeleeHelperStandsIdle.TestTags: TKMTestTagSet;
begin
  Result := [tcKnight, tcCombat, tcPathfinding];
end;


class function TKMTest_MeleeHelperStandsIdle.TestDescription: string;
begin
  Result := 'A knight who cannot fit next to the enemy should wait by his fighting comrade, not go idle elsewhere.';
end;


initialization
  RegisterTest(TKMTest_MeleeHelperStandsIdle);
end.
