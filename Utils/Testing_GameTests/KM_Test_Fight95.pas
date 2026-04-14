unit KM_Test_Fight95;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMTest_Fight95 = class(TKMTest)
  protected
    function DoTick(aTick: Cardinal): Boolean; override;
    procedure SetUp; override;
    procedure CheckResult; override;
    procedure TearDown; override;
  end;


implementation
uses
  System.Math,
  KM_Defaults, KM_Points, KM_CommonUtils,
  KM_GameApp, KM_HandsCollection, KM_Terrain,
  KM_ResMapElements, KM_ResTypes;


{ TKMTest_Fight95 }
procedure TKMTest_Fight95.SetUp;
begin
  inherited;

  DYNAMIC_TERRAIN := False;

  gGameApp.NewEmptyMap(128, 128);

  gHands[0].AddUnitGroup(utSwordFighter, KMPoint(63, 64), TKMDirection(dirE), 8, 24);
  gHands[1].AddUnitGroup(utSwordFighter, KMPoint(65, 64), TKMDirection(dirW), 8, 24);

  gHands[1].UnitGroups[0].OrderAttackUnit(gHands[0].Units[0], True);
end;


procedure TKMTest_Fight95.TearDown;
begin
  inherited;
  DYNAMIC_TERRAIN := True;
end;


function TKMTest_Fight95.DoTick(aTick: Cardinal): Boolean;
begin
  // Continue simulation (True) until one of armies are destroyed
  Result := (gHands[0].Stats.GetUnitQty(utAny) > 0) and (gHands[1].Stats.GetUnitQty(utAny) > 0);
end;


procedure TKMTest_Fight95.CheckResult;
begin
  var minSurvived := Min(gHands[0].Stats.GetUnitQty(utAny), gHands[1].Stats.GetUnitQty(utAny));
  AssertTrue(minSurvived < 8, 'Units should have fought and died');
end;


initialization
  RegisterTest(TKMTest_Fight95);
end.
