unit KM_Test_Walk_PastPacingAnimal;
{$I KaM_Remake.inc}
interface
uses
  KM_UnitGroup, KM_Test;


type
  // An animal that paces to and fro over a diagonal should not keep that diagonal
  // for itself - units walking the crossing diagonal must still get through.
  // A wolf stands in for any animal
  TKMTest_WalkPastPacingAnimal = class(TKMTest)
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

  // People walk on sand, wolves need soil. Sanding everything around (16,16) and (17,17)
  // leaves the wolf nowhere to go but back and forth over that diagonal
  for var I := 15 to 18 do
    for var K := 15 to 18 do
      if not ((K = 16) and (I = 16))
      and not ((K = 17) and (I = 17)) then
        gTerrain.ScriptTrySetTile(K, I, BASE_TERRAIN[tkSand], 0);

  gHands.PlayerAnimals.AddUnit(utWolf, KMPoint(16, 16));

  // The soldier is to walk the crossing diagonal, through (17,16) and (16,17)
  fGroup := gHands[0].AddUnitGroup(utAxeFighter, KMPoint(18, 15), dirSW, 1, 1);
end;


procedure TKMTest_WalkPastPacingAnimal.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  // Let the wolf take up its pacing, then send the soldier across its path
  if aTick = 20 then
    fGroup.OrderWalk(KMPoint(15, 18), True, wtokPlayerOrder);

  // Stop as soon as the soldier is where he was sent
  aKeepGoing := not KMSamePoint(fGroup.FlagBearer.Position, KMPoint(15, 18));

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
