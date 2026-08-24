unit KM_Test_Melee_IdleNextToFight;
{$I KaM_Remake.inc}
interface
uses
  KM_Points, KM_UnitGroup, KM_UnitWarrior, KM_Test;


type
  // Reproduces "soldiers stay afk while group members are in fight". An enemy is boxed in by eight
  // of our men, and the ninth has no free tile closer to the fight than the one under his own feet.
  // GetClosestTile hands that tile back, so TakeNextOrder finds loc = fPositionRound and does nothing.
  TKMTest_MeleeIdleNextToFight = class(TKMTest)
  private const
    ENEMY_X = 32;
    ENEMY_Y = 32;
    OUR_UNITS = 9;         // Eight around the enemy plus the watched one
    FIGHT_START_TICK = 60; // CheckForEnemy runs every 6 ticks, by then they are swinging
    MAX_IDLE_TICKS = 100;  // CheckForFight runs every 5 ticks, 10 seconds is plenty of chances
  private
    fGroup: TKMUnitGroup;
    fWatched: TKMUnitWarrior;
    fWatchedLoc: TKMPoint;
    fIdleTicks: Integer;
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
  KM_Defaults, KM_CommonUtils,
  KM_GameApp, KM_HandsCollection, KM_HandTypes,
  KM_UnitActionWalkTo;


{ TKMTest_MeleeIdleNextToFight }
procedure TKMTest_MeleeIdleNextToFight.SetUp;
begin
  inherited;

  DYNAMIC_TERRAIN := False;
  SHOW_UNIT_ROUTES := True;

  fDuration := 400;

  gGameApp.NewGameEmptyMap(64, 64);

  if gGameApp.Game.ActiveInterface <> nil then
  begin
    gGameApp.Game.ActiveInterface.Viewport.Zoom := 2;
    gGameApp.Game.ActiveInterface.Viewport.Position := KMPointF(ENEMY_X, ENEMY_Y);
  end;

  // Player controlled, so that no AI general orders the squads about
  gHands[0].HandType := hndHuman;
  gHands[1].HandType := hndHuman;

  var enemyLoc := KMPoint(ENEMY_X, ENEMY_Y);

  // Nobody may die, or the brawl resolves and the situation stops being observable
  var enemy := TKMUnitWarrior(gHands[1].AddUnit(utAxeFighter, enemyLoc, False));
  gHands[1].UnitGroups.AddGroup(enemy);
  enemy.HitPointsInvulnerable := True;

  // Eight of ours fill the whole ring around him, spiral indices 1..8
  for var I := 1 to 8 do
  begin
    var W := TKMUnitWarrior(gHands[0].AddUnit(utAxeFighter, GetPositionFromIndex(enemyLoc, I), False));
    W.HitPointsInvulnerable := True;

    if fGroup = nil then
      fGroup := gHands[0].UnitGroups.AddGroup(W)
    else
      fGroup.AddMember(W);
  end;

  // The ninth sits at spiral index 9, so every tile the search tries before his own is taken,
  // and his own is let through by the KMSamePoint(T, aOriginLoc) half of the occupancy check
  fWatchedLoc := GetPositionFromIndex(enemyLoc, 9);
  fWatched := TKMUnitWarrior(gHands[0].AddUnit(utAxeFighter, fWatchedLoc, False));
  fWatched.HitPointsInvulnerable := True;
  fGroup.AddMember(fWatched);
end;


procedure TKMTest_MeleeIdleNextToFight.TearDown;
begin
  inherited;
  DYNAMIC_TERRAIN := True;
  SHOW_UNIT_ROUTES := False;
end;


procedure TKMTest_MeleeIdleNextToFight.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  // Read the stats, not the unit pointers, so a broken setup fails here and not on freed memory
  AssertEquals(OUR_UNITS, gHands[0].Stats.GetUnitQty(utAny), 'Everybody is invulnerable, nobody should die');

  if aTick < FIGHT_START_TICK then Exit;

  AssertTrue(fGroup.InFight, Format('Tick %d: the group was expected to be locked in a fight by now', [aTick]));

  if (fWatched.Action is TKMUnitActionWalkTo)
    or fWatched.InFight
    or not KMSamePoint(fWatched.Position, fWatchedLoc) then
    fIdleTicks := 0
  else
    Inc(fIdleTicks);

  AssertTrue(fIdleTicks <= MAX_IDLE_TICKS,
    Format('Tick %d: axe fighter %d has been standing idle at %s for %d ticks '
         + 'while the rest of his group fights the enemy at %d:%d',
           [aTick, fWatched.UID, fWatchedLoc.ToString, fIdleTicks, ENEMY_X, ENEMY_Y]));
end;


procedure TKMTest_MeleeIdleNextToFight.CheckResult;
begin
  // The watched member is checked on every tick
end;


class function TKMTest_MeleeIdleNextToFight.TestTags: TKMTestTagSet;
begin
  Result := [tcAxeFighter, tcCombat, tcPathfinding];
end;


class function TKMTest_MeleeIdleNextToFight.TestDescription: string;
begin
  Result := 'A melee group member should not stand idle next to a fight his comrades are in.';
end;


initialization
  RegisterTest(TKMTest_MeleeIdleNextToFight);
end.
