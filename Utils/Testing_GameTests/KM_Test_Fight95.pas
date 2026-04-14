unit KM_Test_Fight95;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMRunnerFight95 = class(TKMTest)
  protected
    function OnTickCondition(aTick: Cardinal): Boolean; override;
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
    procedure TearDown; override;
  end;

implementation
uses
  Windows, SysUtils, Classes, Math,
  Generics.Collections, Generics.Defaults,
  KM_CommonClasses, KM_Defaults, KM_Points, KM_CommonUtils,
  KM_GameApp, KM_Log, KM_HandsCollection, KM_HouseCollection, KM_Resource,
  KM_Terrain, KM_Units, KM_Campaigns, KM_Houses,
  KM_GameParams,
  KM_Exceptions,
  KM_CampaignTypes,
  KM_HandSpectator, KM_ResHouses, KM_Hand, KM_HandTypes, KM_UnitsCollection, KM_UnitGroup,
  KM_GameSettings,
  KM_CommonTypes, KM_MapTypes, KM_FileIO, KM_Game, KM_GameInputProcess, KM_GameTypes, KM_InterfaceGame,
  KM_UnitGroupTypes,
  KM_ResTypes, KM_CampaignClasses;

{ TKMRunnerFight95 }
procedure TKMRunnerFight95.SetUp;
begin
  inherited;
  fResults.ValueCount := 2;
  DYNAMIC_TERRAIN := False;

  gGameApp.NewEmptyMap(128, 128);

  gHands[0].AddUnitGroup(utSwordFighter, KMPoint(63, 64), TKMDirection(dirE), 8, 24);
  gHands[1].AddUnitGroup(utSwordFighter, KMPoint(65, 64), TKMDirection(dirW), 8, 24);

  gHands[1].UnitGroups[0].OrderAttackUnit(gHands[0].Units[0], True);
end;


procedure TKMRunnerFight95.TearDown;
begin
  inherited;
  DYNAMIC_TERRAIN := True;
end;

function TKMRunnerFight95.OnTickCondition(aTick: Cardinal): Boolean;
begin
  // Continue simulation (True) until one of armies are destroyed
  Result := (gHands[0].Stats.GetUnitQty(utAny) > 0) 
  and (gHands[1].Stats.GetUnitQty(utAny) > 0);
end;

procedure TKMRunnerFight95.Execute(aRun: Integer);
begin
  SetKaMSeed(aRun + 1);
  SimulateGame;

  fResults.Value[aRun, 0] := gHands[0].Stats.GetUnitQty(utAny);
  fResults.Value[aRun, 1] := gHands[1].Stats.GetUnitQty(utAny);

  AssertTrue((fResults.Value[aRun, 0] < 8) or (fResults.Value[aRun, 1] < 8), 'Units should have fought and died');

  gGameApp.StopGame(grSilent);
end;

initialization
  RegisterTest(TKMRunnerFight95);
end.
