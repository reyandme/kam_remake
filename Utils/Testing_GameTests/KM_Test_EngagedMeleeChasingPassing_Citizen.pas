unit KM_Test_EngagedMeleeChasingPassing_Citizen;

{$I KaM_Remake.inc}
interface
uses
  KM_Test,
  KM_Units,
  KM_UnitWarrior;

type
  TKMTest_EngagedMeleeChasingPassing_Citizen = class(TKMTest)
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
  KM_Defaults, KM_ResTypes,
  KM_GameApp, KM_HandsCollection, KM_HandTypes, KM_Terrain, KM_Points,
  KM_UnitGroupTypes;

procedure TKMTest_EngagedMeleeChasingPassing_Citizen.SetUp;
begin
  inherited;

  //All pikes should be in fight at this time.
  fDuration := 100;

  gGameApp.NewGameEmptyMap(32, 32);

  DYNAMIC_TERRAIN := False;

  if gGameApp.Game.ActiveInterface <> nil then
    gGameApp.Game.ActiveInterface.Viewport.Zoom := 0.75;

  gHands[0].HandType := hndHuman;
  gHands[1].HandType := hndHuman;

  gHands[0].AddUnitGroup(utPikeman, TKMPoint.New(9, 15), dirE, 2, 2);
  gHands[1].AddUnit(utBaker, TKMPoint.New(11, 14));

  gHands[1].AddUnitGroup(utMilitia, TKMPoint.New(10, 17), dirN, 3, 3);

  gHands[1].AddHouse(htBakery, 16, 9, true);
end;


procedure TKMTest_EngagedMeleeChasingPassing_Citizen.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  if aTick = 5 then
    gHands[0].UnitGroups[0].OrderWalk(TKMPoint.New(10, 15), True, wtokPlayerOrder, dirE, True);

  if aTick = 12 then
    gHands[1].UnitGroups[0].OrderWalk(TKMPoint.New(10, 16), True, wtokPlayerOrder, dirN, True);

  //All pikes are fighting 1 group of militia and all works correct.
  if gHands[0].UnitGroups[0].InFightAllMembers then
    aKeepGoing := False;

end;


class function TKMTest_EngagedMeleeChasingPassing_Citizen.TestTags: TKMTestTagSet;
begin
  Result := [tcCombat];
end;


class function TKMTest_EngagedMeleeChasingPassing_Citizen.TestDescription: string;
begin
  Result := 'After melee group gets into fight, members should help instead of chasing passing by citizens.';
end;


procedure TKMTest_EngagedMeleeChasingPassing_Citizen.TearDown;
begin
  inherited;
  DYNAMIC_TERRAIN := True;
end;


initialization
  RegisterTest(TKMTest_EngagedMeleeChasingPassing_Citizen);
end.
