unit KM_Test_Walk_PastPacingAnimal;
{$I KaM_Remake.inc}
interface
uses
  KM_UnitGroup, KM_Test;


type
  // An animal that paces to and fro over a diagonal should not keep that diagonal
  // for itself - units walking the crossing diagonal must still get through.
  // A wolf stands in for them all, every animal walks with TKMUnitActionSteer
  TKMTest_WalkPastPacingAnimal = class(TKMTest)
  private const
    // The wolf's two tiles, diagonal to each other
    WOLF_X = 16;
    WOLF_Y = 16;
    // The soldier walks the crossing diagonal, through (17,16) and (16,17)
    FROM_X = 18;
    FROM_Y = 15;
    TO_X = 15;
    TO_Y = 18;
  private
    fGroup: TKMUnitGroup;
  protected
    procedure DoTick(aTick: Cardinal; var aKeepGoing: Boolean); override;
    procedure SetUp; override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;


implementation
uses
  KM_Defaults, KM_Points,
  KM_GameApp, KM_HandsCollection, KM_HandTypes, KM_Terrain,
  KM_ResTilesetTypes, KM_UnitGroupTypes;


{ TKMTest_WalkPastPacingAnimal }
procedure TKMTest_WalkPastPacingAnimal.SetUp;
begin
  inherited;

  fDuration := 600;

  gGameApp.NewGameEmptyMap(32, 32);

  // Player controlled, so that no AI general orders the squads about
  gHands[0].HandType := hndHuman;

  // People walk on sand, wolves need soil. Sanding everything around the two
  // diagonal tiles leaves the wolf nowhere to go but back and forth between them
  for var I := WOLF_Y - 1 to WOLF_Y + 2 do
    for var K := WOLF_X - 1 to WOLF_X + 2 do
      if not ((K = WOLF_X) and (I = WOLF_Y))
      and not ((K = WOLF_X + 1) and (I = WOLF_Y + 1)) then
        gTerrain.ScriptTrySetTile(K, I, BASE_TERRAIN[tkSand], 0);

  gHands.PlayerAnimals.AddUnit(utWolf, KMPoint(WOLF_X, WOLF_Y));

  fGroup := gHands[0].AddUnitGroup(utAxeFighter, KMPoint(FROM_X, FROM_Y), dirSW, 1, 1);
end;


procedure TKMTest_WalkPastPacingAnimal.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  // Let the wolf take up its pacing, then send the soldier across its path
  if aTick = 20 then
    fGroup.OrderWalk(KMPoint(TO_X, TO_Y), True, wtokPlayerOrder);

  // Stop as soon as the soldier is where he was sent
  aKeepGoing := not KMSamePoint(fGroup.FlagBearer.Position, KMPoint(TO_X, TO_Y));

  if aKeepGoing and TimeIsOut then
    AssertFail('Soldier did not get past the wolf');
end;


class function TKMTest_WalkPastPacingAnimal.TestTags: TKMTestTagSet;
begin
  Result := [tcWolf, tcAxeFighter, tcPathfinding];
end;


class function TKMTest_WalkPastPacingAnimal.TestDescription: string;
begin
  Result := 'A soldier sent across the path of an animal pacing between two tiles should reach his destination.';
end;


initialization
  RegisterTest(TKMTest_WalkPastPacingAnimal);
end.
