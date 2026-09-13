unit KM_Test_MeleeMilitiaSwarmsKnights;

{$I KaM_Remake.inc}
interface
uses
  KM_Test,
  KM_UnitWarrior;

type
  TKMTest_MeleeMilitiaSwarmsKnight = class(TKMTest)
  protected
    procedure SetUp; override;
    procedure DoTick(aTick: Cardinal; var aKeepGoing: Boolean); override;
    procedure TearDown; override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;


implementation
uses
  KM_Defaults,
  KM_GameApp, KM_HandsCollection, KM_HandTypes, KM_Terrain, KM_Points,
  KM_UnitGroupTypes;


procedure TKMTest_MeleeMilitiaSwarmsKnight.SetUp;
begin
  inherited;

  fDuration := 90;

  gGameApp.NewGameEmptyMap(32, 32);

  DYNAMIC_TERRAIN := False;

  if gGameApp.Game.ActiveInterface <> nil then
    gGameApp.Game.ActiveInterface.Viewport.Zoom := 0.8;

  gHands[0].HandType := hndHuman;
  gHands[1].HandType := hndHuman;
  gHands[1].FlagColor := MP_PLAYER_COLORS[13];

  gHands[0].AddUnitGroup(utKnight, TKMPoint.New(16, 16), dirS, 1, 1);
  gHands[1].AddUnitGroup(utMilitia, TKMPoint.New(16, 17), dirN, 10, 50);
end;


procedure TKMTest_MeleeMilitiaSwarmsKnight.TearDown;
begin
  inherited;
  DYNAMIC_TERRAIN := True;
end;


procedure TKMTest_MeleeMilitiaSwarmsKnight.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  if TimeIsOut then
    AssertTrue(gHands[0].Units.Count = 0, 'Knight should have been killed within alloted time');
end;


class function TKMTest_MeleeMilitiaSwarmsKnight.TestTags: TKMTestTagSet;
begin
  Result := [tcCombat];
end;


class function TKMTest_MeleeMilitiaSwarmsKnight.TestDescription: string;
begin
  Result := 'Militias should swarm and kill the Knight within alloted time.';
end;


initialization
  RegisterTest(TKMTest_MeleeMilitiaSwarmsKnight);
end.
