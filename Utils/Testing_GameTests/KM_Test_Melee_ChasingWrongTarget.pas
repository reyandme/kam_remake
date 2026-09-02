unit KM_Test_Melee_ChasingWrongTarget;

{$I KaM_Remake.inc}
interface
uses
  KM_Test,
  KM_Points,
  KM_UnitGroupTypes,
  KM_UnitWarrior;

type
  TKMTest_Melee_ChasingWrongTarget = class(TKMTest)
  private
    wrongChasedUnit: TKMUnitWarrior;
  protected
    procedure SetUp; override;
    procedure DoTick(aTick: Cardinal; var aKeepGoing: Boolean); override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;


implementation
uses
  SysUtils,
  KM_Defaults,
  KM_GameApp, KM_HandsCollection, KM_HandTypes, KM_Terrain;

procedure TKMTest_Melee_ChasingWrongTarget.SetUp;
begin
  inherited;

  fDuration := 100;

  gGameApp.NewGameEmptyMap(32, 32);

  if gGameApp.Game.ActiveInterface <> nil then
    gGameApp.Game.ActiveInterface.Viewport.Zoom := 0.75;

  gTerrain.SetObject(TKMPoint.New(10, 13), 8);

  gHands[0].HandType := hndHuman;
  gHands[1].HandType := hndHuman;

  gHands[0].AddUnitGroup(utPikeman, TKMPoint.New(9, 14), dirE, 3, 3);
  gHands[1].AddUnitGroup(utMilitia, TKMPoint.New(11, 14), dirNE, 1, 1);

  wrongChasedUnit := gHands[1].UnitGroups[0].Members[0];

  gHands[1].AddUnitGroup(utMilitia, TKMPoint.New(10, 17), dirN, 3, 3);
end;


procedure TKMTest_Melee_ChasingWrongTarget.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  if aTick = 1 then
    gHands[0].UnitGroups[0].OrderAttackUnit(gHands[1].UnitGroups[0].Members[0], True);
  if aTick = 6 then
    gHands[1].UnitGroups[0].OrderWalk(TKMPoint.New(17, 8), True, wtokPlayerOrder, dirNE, true);
  if aTick = 7 then
    gHands[1].UnitGroups[1].OrderWalk(TKMPoint.New(10, 16), True, wtokPlayerOrder, dirN, true);

  AssertTrue((wrongChasedUnit <> nil) and not (wrongChasedUnit.IsDead or wrongChasedUnit.InFight), 'Soldiers chased wrong units.');
end;


class function TKMTest_Melee_ChasingWrongTarget.TestTags: TKMTestTagSet;
begin
  Result := [tcCombat];
end;


class function TKMTest_Melee_ChasingWrongTarget.TestDescription: string;
begin
  Result := 'After melee group gets into fight members should help instead of chasing soldiers of different group.';
end;


initialization
  RegisterTest(TKMTest_Melee_ChasingWrongTarget);
end.
