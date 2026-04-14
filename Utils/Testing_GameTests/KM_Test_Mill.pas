unit KM_Test_Mill;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;

type
  TKMRunnerMill_Process = class(TKMTest)
  protected
    function DoTick(aTick: Cardinal): Boolean; override;
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
  public
    class function TestCategories: TKMTestCategorySet; override;
    class function TestDescription: string; override;
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

procedure TKMRunnerMill_Process.SetUp;
var
  H: TKMHouse;
begin
  inherited;
  fResults.ValueCount := 1;
  gGameApp.NewEmptyMap(32, 32);

  // Add the mill
  H := gHands[0].AddHouse(htMill, 16, 16, False);

  // Input 1 for Mill is wtCorn
  H.ResIn[1] := 1;

  // Add the baker unit
  gHands[0].AddUnit(utBaker, KMPoint(16, 17));
end;

function TKMRunnerMill_Process.DoTick(aTick: Cardinal): Boolean;
begin
  // Keep running until flour is produced
  Result := gHands[0].Stats.GetWaresProduced(wtFlour) = 0;
end;

procedure TKMRunnerMill_Process.Execute(aRun: Integer);
begin
  SetKaMSeed(aRun+1);
  SimulateGame;

  // Check if it produced something
  fResults.Value[aRun, 0] := gHands[0].Stats.GetWaresProduced(wtFlour);

  AssertTrue(fResults.Value[aRun, 0] >= 1, 'Mill should have processed corn into flour');

  gGameApp.StopGame(grSilent);
end;

class function TKMRunnerMill_Process.TestCategories: TKMTestCategorySet;
begin
  Result := [tcMill, tcEconomy];
end;

class function TKMRunnerMill_Process.TestDescription: string;
begin
  Result := 'Tests the mill''s ability to process one corn from the internal stock into flour.';
end;

initialization
  RegisterTest(TKMRunnerMill_Process);
end.
